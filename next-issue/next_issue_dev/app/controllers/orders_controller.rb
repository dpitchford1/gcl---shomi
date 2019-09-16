class OrdersController < ApplicationController
  before_action :redirect_if_not_logged
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :check_billing_option, only: [:new, :create]
  before_action :check_eligibility, except: [:history, :cancel_order, :update]
  before_action :set_no_cache, only: [:new, :order_summary, :create, :callback]
  before_action :find_tos, only: [:index, :new, :order_summary, :create, :callback]
  before_action :clear_loyalty, only: [:index, :new]

  def index
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    if @offer.nil?
      redirect_to profiles_path, notice: t('orders.notice.try_again')
    elsif session[:promo_code] && !@current_session.profile.purchased? && !@current_session.profile.eligible? && PromoCode::REDEMPTION_CODE_TYPES.include?(session[:promo_code].code_type)
      redirect_to promo_contact_path
    elsif !@current_session.profile.accounts.any?
      redirect_to new_order_path(order: { billing_option: 'cc'})
    end
    # setup default params to forms based off previous order
    default_order_attributes = (ENV['user_orders'] && @current_session.latest_order.try(:order_attributes)) ? @current_session.latest_order.order_attributes : {}

    @order = Order.new(default_order_attributes.merge({ optin: @current_session.profile.try(:optin), optin_account_token: @current_session.profile.try(:optin_account_token) }))

    params[:order] = { billing_option: nil }
  end

  def show
  end

  def new
    redirect_to promo_contact_path if session[:promo_code] && !@current_session.profile.eligible? && !@current_session.profile.purchased? && PromoCode::REDEMPTION_CODE_TYPES.include?(session[:promo_code].code_type)
    # setup default params to forms based off previous order
    default_order_attributes = (ENV['user_orders'] && @current_session.latest_order.try(:order_attributes)) ? @current_session.latest_order.order_attributes : {}
    default_cc_attributes = (ENV['user_orders'] && @current_session.latest_order.try(:credit_attributes)) ? @current_session.latest_order.credit_attributes : {}

    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @order = extract_object(:order) || Order.new(default_order_attributes.merge(order_params))
    @order.optin = @current_session.profile.try(:optin)
    @order.optin_account_token = @current_session.profile.try(:optin_account_token)
    @order.billing_option = 'cc' unless @current_session.profile.accounts.any?
    # Set default rogers account token to the last one used in billing
    recent_order = @current_session.profile.user_orders.first
    if @order.billing_option == 'rogersbill' && recent_order.try(:billing_option) == 'rogersbill'
      @current_session.profile.accounts.each do |account|
        @order.rogers_account_token = account.account_token if account.account_token.match(/#{recent_order.billing_account.to_s}/)
      end
    end
    @credit_card = extract_object(:credit_card) || CreditCard.new(default_cc_attributes.merge(cc_params))
  end

  def order_summary
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @order  = extract_object(:order) || Order.new(order_params)
    @order.province! unless @order.province
    @order.price = @offer.price
    @order.offer_id = @offer.offer_id

    # avoid validating phone/email/dob for nextissue orders (don't skip validation for promo contact form)
    skip_contact_detail_validation if ENV['skip_contact_detail_validation'] && !params[:validate_contact_data]

    # if this order has optin true, skip the phone/dob/account validation
    if @order.optin
      %w(birthdate phone_number rogers_account_token).each { |f| @order.try("skip_#{f}_validation!") }
    end

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
    @order.offer_id = @offer.offer_id
    @order.profile = @current_session.profile

    # avoid validating phone/email/dob for nextissue orders
    skip_contact_detail_validation if ENV['skip_contact_detail_validation']
    # if this order has optin true, skip the phone/dob/account validation
    if @order.optin
      %w(birthdate phone_number rogers_account_token).each { |f| @order.try("skip_#{f}_validation!") }
    end

    respond_to do |format|
      if @order.valid?
        # Set the offer to the premium offer when the promo code is redemption (termedsubscription)
        overwrite_offer_id = {}
        if @order.billing_option == 'free' && @order.promo_code && session[:promo_code].try(:is_valid_redemption?)
          if !ENV['redemption_top_up'] || session[:promo_code].valid_for?('premium')
            overwrite_offer_id[:offer_id] = ENV['premium_offer_id']
          else
            overwrite_offer_id[:offer_id] = ENV['basic_offer_id']
          end
        end

        # Clear loyalty info when not 'NoFreeTrial' and no membership number for loyalty
        overwrite_loyalty_info = {}
        if @order.loyalty_code && (@order.membership_type != 'Charger' && (@order.membership_number.blank? || @order.membership_number.downcase == 'none'))
          overwrite_loyalty_info = {loyalty_code: '', membership_number: '', membership_type: ''}
        end

        # flag to tell hardworker to top up
        topup_on_completion = {topup_on_completion: false } 
        
        puts "ORDER OFFER TYPE #{@order.offer_type}"
        if !@order.offer_type.nil? && @order.offer_type == "topup"
          #when submitting billing information for tupup, perform the topup changeoffer automatically after completing the order billing update
          topup_on_completion = {topup_on_completion: true } 
        end

        profile_parameters = {user_is_active: @current_session.profile.eligible?, user_is_on_redemption: @current_session.profile.has_redemption?, user_has_billing_info: @current_session.profile.user_has_billing_info?, account_summary_token: @current_session.profile.account_summary_token, currently_on_basic: @current_session.profile.basic?}
        address_parameters = {}
        address_parameters[:street] = "#{@order.street}|_#{@order.address2}" if @order.address2.present?
        background_alt_message!(t('pages.background.cc_alternative_message')) if ['cc', 'rogersbill'].include?(@order.billing_option)
        background_notice!(t('orders.notice.processing_order'))

        operation = { operation: order_params[:operation].blank? ? 'create' : order_params[:operation] }
        HardWorker.perform_async(session.id, :order, order_params.merge(operation).merge(overwrite_offer_id).merge(overwrite_loyalty_info).merge(profile_parameters).merge(topup_on_completion).merge(address_parameters))
        format.js { render 'pages/background_job' }
      else
        redirect, session[:notice_type], session[:notice] = *@order.redirect
        session[:object] = { order: @order } 
        format.js { render js: "window.location = '#{redirect}'" }
      end
    end
  end

  def update
    # Update an order's offer
    respond_to do |format|
      if !order_params[:offer_id].blank?
        background_alt_message!(t('pages.background.cc_alternative_message'))
        background_notice!(t('orders.notice.processing_order'))
        HardWorker.perform_async(session.id, :change_offer, order_params.merge({ user_is_on_redemption: @current_session.profile.has_redemption?, term_type: @current_session.profile.term_type }))
        format.js { render 'pages/background_job' }
      else
        @order = Order.new(order_params)
        redirect, session[:notice_type], session[:notice] = *@order.redirect
        session[:object] = { order: @order }
        format.js { render js: "window.location = '#{redirect}'" }
      end
    end
  end

  def callback
    @order = extract_object(:order) || Order.new
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    passthrough_params = Rack::Utils.parse_query( Gibberish::AES.new(session.id).dec(params[:field_passthrough1].gsub(/\n/,'').gsub(' ', '+') )) rescue {}
    passthrough_params[:birthdate] = passthrough_params.delete('birthdate[]')
    @credit_card = CreditCard.new(passthrough_params)

    # avoid validating phone/email/dob for nextissue orders
    skip_contact_detail_validation if ENV['skip_contact_detail_validation']

    @order.credit_card = @credit_card
    @credit_card.process_errors(params)
    session[:credit_card] = @credit_card
    
    @order.assign_attributes(
      operation: @credit_card.operation,
      offer_type: @credit_card.offer_type,
      billing_option: 'cc',
      offer_id: @offer.offer_id,
      province: @credit_card.field_creditCardState,
      street: @credit_card.field_creditCardAddress1,
      address2: @credit_card.field_creditCardAddress2,
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
      loyalty_code: @credit_card.loyalty_code,
      membership_number: @credit_card.membership_number,
      membership_type: @credit_card.membership_type,
      price: @offer.price,
      promo_code: @credit_card.promo_code,
      code_type: @credit_card.code_type,
      desc: @credit_card.desc,
      term_type: @current_session.profile.term_type
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
    @credit_card.validation_type = session[:exclusive_creditcard] || session[:loyalty_code].try(:validation_type)
    respond_to do |format|
      if !@credit_card.valid? && cc_params[:validate]
        format.json { render json: {name: @credit_card.class.to_s.underscore, errors: @credit_card.errors.messages } }

      else
        format.json { render json: {} }
      end
    end
  end


  def promo_contact
    puts "SESSION OFFER ID"
    puts session[:offer_id]
    membership_type = "redemption"
    tos_id = Tos.get_tos_id_for_membership(membership_type)
    @tos = Tos.get_tos({ version: @current_session.profile.tos_version, id: tos_id })
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    already_purchased_offer = !@current_session.profile.eligible? && !@current_session.profile.purchased?

    if session[:promo_code] && ( already_purchased_offer || ENV["eligible_allowed_to_order"] )
      @order = Order.new(@current_session.profile.attributes.merge({ billing_option: "free", offer_id: @offer.offer_id, promo_code: session[:promo_code].code, code_type: session[:promo_code].code_type, desc: session[:promo_code].attributes[:description] }))
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

  def cancel_order
    respond_to do |format|
      if !order_params[:order_id].blank? && !order_params[:validate]
        # Remove promo/redemption code from session to send user back to profiles index instead of promo contact
        session[:promo_code] = nil
        format.js {
          background_notice!(t('orders.notice.cancelling_subscription'))
          HardWorker.perform_async(session.id, :cancel_order, order_params)
          render 'pages/background_job'
        }
      else
        messages = {}
        messages[:order_id] = ["missing order id"] if order_params[:order_id].blank?
        format.json { render json: {name: 'order', errors: messages } }
      end
    end
  end

  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: t("orders.notice.destroyed") }
    end
  end

  private
  def skip_contact_detail_validation
    %w(birthdate phone_number).each do |f|
      @order.try("skip_#{f}_validation!") if @order.try(f).blank?
    end
    %w(birthdate field_phone field_email).each do |f|
      @credit_card.try("skip_#{f}_validation!") if @credit_card.try(f).blank?
    end
  end

  def check_eligibility
    if @current_session.try(:profile).try(:eligible?)
      redirect_to profiles_path, alert: t('orders.notice.eligible') unless ENV["eligible_allowed_to_order"]
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
    params.permit(:tos, :tos2, :nhl_opt_in, :field_creditCardNumber, :field_cardSecurityCode, :field_creditCardHolderName, :field_creditCardState, :field_creditCardAddress1, :field_creditCardAddress2, 
                  :loyalty_code, :membership_number, :membership_type, :operation, :offer_type,
                  :field_creditCardCity, :field_creditCardPostalCode, :field_phone, :field_email, :field_creditCardExpirationMonth, :field_creditCardExpirationYear, :field_creditCardCountry, :validate, :birthdate, birthdate: []).symbolize_keys
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_params
    params.require(:order).permit(:existing_offer_type, :order_id, :phone_number, :promo_code, :code_type, :desc, :full_name, :first_name, :last_name, :street, :address2, :city, :postal_code, :billing_option, :province, :cc_token, :auto_renew, :campaign_identifier, :operation, :offer_type, :term_type,
                                  :cancellation_reason, :loyalty_code, :membership_number, :membership_type, :optin, :optin_account_token, :tos, :tos2, :nhl_opt_in, :rogers_account_token, 
                                  :offer_id, :optin_email, :masked_cc, :cc_type, :validate, :birthdate, birthdate: []).symbolize_keys
  end

  def find_tos
    if @current_session.profile.disable_loyalty?
      membership_type = ""
    else
      membership_type = session[:loyalty_code].try(:membership_type)
    end
    tos_id = Tos.get_tos_id_for_membership(membership_type)

    # load topup T&C for users who can top up & have topup offer selected
    tos_id = "#{ENV['APP_NAME']}topup" if @current_session.profile.can_top_up? && params[:offer_type] == 'topup'

    @tos = Tos.get_tos({ version: @current_session.profile.tos_version, id: tos_id })
  end

  def clear_loyalty
    session[:loyalty_code] = nil if session[:loyalty_code].try(:membership_type) == 'Charger' && @current_session.try(:latest_order).try(:status).to_s.downcase == 'cancelled'
  end
end
