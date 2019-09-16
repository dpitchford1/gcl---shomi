class OrdersController < ApplicationController
  before_action :redirect_if_not_logged
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :check_billing_option, only: [:new, :create]
  before_action :check_eligibility, except: [:history, :cancel]
  before_action :set_no_cache, only: [:new, :order_summary, :create, :callback]

  def index
    redirect_to new_order_path(order: { billing_option: 'cc'}) unless @current_session.profile.accounts.any?

    @order = Order.new
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @tos = Tos.get_tos(version: @current_session.profile.tos_version)

    params[:order] = { billing_option: nil }
    redirect_to profiles_path, notice: t('orders.notice.try_again') unless @offer
  end

  def show
  end

  def new
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @order = extract_object(:order) || Order.new(order_params)
    @order.billing_option = 'cc' unless @current_session.profile.accounts.any?
    @tos = Tos.get_tos(version: @current_session.profile.tos_version)
    @credit_card = extract_object(:credit_card) || CreditCard.new
  end

  def order_summary
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @order  = extract_object(:order) || Order.new(order_params)
    @order.province! unless @order.province
    @order.price = @offer.price
    @order.offer_id = @offer.offer_id
    @tos = Tos.get_tos(version: @current_session.profile.tos_version)

    respond_to do |format|
      if @order.valid? && !order_params[:validate]
        format.html { render :order_summary }
      else
        format.json { render json: {name: @order.class.to_s.underscore, errors: @order.errors.messages } }
      end
    end
  end

  def create
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @order = Order.new(order_params)
    @order.operation = 'create'
    @order.offer_id = @offer.offer_id
    @tos = Tos.get_tos(version: @current_session.profile.tos_version)
    @order.profile = @current_session.profile

    respond_to do |format|
      if @order.valid?
        background_alt_message!(t('pages.background.cc_alternative_message')) if ['cc', 'rogersbill'].include?(@order.billing_option)
        background_notice!(t('orders.notice.processing_order'))
        HardWorker.perform_async(session.id, :order, order_params.merge(operation: 'create'))
        format.js { render 'pages/background_job' }
      else
        redirect, session[:notice_type], session[:notice] = *@order.redirect
        session[:object] = { order: @order } 
        format.js { render js: "window.location = '#{redirect}'" }
      end
    end
  end

  def callback
    @order = extract_object(:order) || Order.new
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @tos = Tos.get_tos(version: @current_session.profile.tos_version)
    passthrough_params = Rack::Utils.parse_query( Gibberish::AES.new(session.id).dec(params[:field_passthrough1].gsub(/\n/,'').gsub(' ', '+') )) rescue {}
    passthrough_params[:birthdate] = passthrough_params.delete('birthdate[]')
    @credit_card = CreditCard.new(passthrough_params) 
    @order.credit_card = @credit_card
    @credit_card.process_errors(params)
    session[:credit_card] = @credit_card

    @order.assign_attributes(
      operation: 'create',
      billing_option: 'cc',
      offer_id: @offer.offer_id,
      province: @credit_card.field_creditCardState,
      street: @credit_card.field_creditCardAddress1,
      postal_code: @credit_card.field_creditCardPostalCode,
      city: @credit_card.field_creditCardCity,
      full_name: @credit_card.field_creditCardHolderName, 
      cc_token: params[:refId],
      cc_type: @credit_card.field_creditCardType,
      masked_cc: @credit_card.masked_cc,
      optin_email: false,
      birthdate: @credit_card.birthdate,
      auto_renew: @credit_card.auto_renew,
      phone_number: @credit_card.field_phone,
      tos: @credit_card.tos,
      price: @offer.price
    )
    if params[:success] == 'true' && !@credit_card.errors.any? && @order.valid? 
      render :order_summary
    else
      session[:object] = { credit_card: @credit_card }
      Rails.logger.error "CC error for #{@session.username}: #{@credit_card.errors.messages[:base].join("\n")}" if @credit_card.errors.messages[:base]
      redirect_to new_order_path(order: { billing_option: 'cc'})
    end
  end

  def verify_cc
    @credit_card = CreditCard.new(cc_params)
    respond_to do |format|
      if !@credit_card.valid? && cc_params[:validate]
        format.json { render json: {name: @credit_card.class.to_s.underscore, errors: @credit_card.errors.messages } }

      else
        format.json { render json: {} }
      end
    end
  end


  def promo_contact
    @tos = Tos.get_tos(version: @current_session.profile.tos_version)
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])

    if session[:promo_code]
      @order = extract_object(:order) || Order.new(@current_session.profile.attributes.merge({billing_option: "free", offer_id: @offer.offer_id, promo_code: session[:promo_code].code}))
    else
      redirect_to root_path
    end
  end

  def history
    @order_history = extract_object(:order_history)
    respond_to do |format|
      format.html { render :history }
      format.js {
        background_notice!(t('sessions.retrieving_info'))
        HardWorker.perform_async(session.id, :order_history)
        render 'pages/background_job'
      }
    end
  end


  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: t("orders.notice.destroyed") }
    end
  end

  private

  def check_eligibility
    if @current_session.try(:profile).try(:eligible?)
      redirect_to profiles_path, alert: t('orders.notice.eligible')
    end
  end

  def check_billing_option
    redirect_to orders_path, alert: t('orders.notice.billing_not_exist') unless params[:order] && CONFIG[:billing_options].include?(order_params[:billing_option].try(:to_sym))
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_order
    @order = Order[params[:id]]
  end

  def cc_params
    params.permit(:tos, :tos2, :nhl_opt_in, :field_creditCardNumber, :field_cardSecurityCode, :field_creditCardHolderName, :field_creditCardState, :field_creditCardAddress1, 
                  :field_creditCardCity, :field_creditCardPostalCode, :field_phone, :field_email, :field_creditCardExpirationMonth, :field_creditCardExpirationYear, :field_creditCardCountry, :validate, :birthdate, birthdate: []).symbolize_keys
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_params
    params.require(:order).permit(:phone_number, :promo_code, :full_name, :first_name, :last_name, :street, :city, :postal_code, :billing_option, :province, :cc_token, :auto_renew, :tos, :tos2, :nhl_opt_in, :rogers_account_token, 
                                  :offer_id, :optin_email, :masked_cc, :cc_type, :validate,  :birthdate, birthdate: []).symbolize_keys
  end
end
