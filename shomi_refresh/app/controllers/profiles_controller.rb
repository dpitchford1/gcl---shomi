class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]
  before_action :redirect_if_logged, only: [:new, :create]
  before_action :redirect_if_not_logged, only: [:index, :accounts, :search_accounts, :link_accounts, :edit, :update]

  def index
    #cancel promo code
    session[:promo_code] = nil if params[:cancel_promo_code]

    if !@current_session.profile.eligible? && @current_session.profile.try(:optin)
      redirect_to orders_path
    elsif session[:promo_code] && !@current_session.profile.purchased? && !@current_session.profile.eligible? # || @current_session.profile.cannot_buy?
      #redirect users to promo_contact_path if the user doesn't already have the service and if a promo_code is in session
      redirect_to promo_contact_path
    end

    session.delete(:user_region)

    if ENV['APP_NAME'] == 'gcl'
      cookies[:portal_eligible] = { value: true, expires: 1.year.from_now } if @current_session.try(:profile).try(:level) == 'purchased' || @current_session.try(:profile).try(:eligible?) 
      if cookies[:eligibility_checked]
        redirect_to root_path unless params[:order_id]
      else
        cookies[:eligibility_checked] = { value: true, expires: 1.year.from_now }
      end
    elsif ENV['APP_NAME'] == 'shomi' &&@current_session.try(:profile).try(:level) == "noRogersAccount"
      redirect_to profiles_accounts_path
    else
      if @current_session.try(:profile).try(:level) == 'purchased'
        cookies[:portal_eligible] = { value: true, expires: 1.year.from_now }
        redirect_to root_path unless params[:order_id]
      else
        cookies.delete(:portal_eligible)
      end
    end

    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @promo_code = PromoCode.new
    @order = Order[params[:order_id]] 
    @credit_card = CreditCard.new if @order && @order.billing_option == 'cc'
  end

  def show
  end

  def new
    @profile = extract_object(:profile) || Profile.new
    @tos = Tos.latest
    @questions = Question.all
  end

  def edit
    @tos = Tos.latest
  end

  def create
    # Assign operation, and set username, same as email
    params[:profile].merge!({operation: 'create', username: profile_params[:email_address]})

    @profile = Profile.new(profile_params)
    @tos = Tos.latest

    respond_to do |format|
      if @profile.valid? && !profile_params[:validate]

        background_notice!(t('sessions.retrieving_info'))
        HardWorker.perform_async(session.id, :register_and_login, profile_params.merge({ip_address: request.ip, user_region: session[:user_region] }))

        format.js { render 'pages/background_job' }
      else
        session[:registration] = 'registration failed'
        format.json { render json: {name: @profile.class.to_s.underscore, errors: @profile.errors.messages } }
      end
    end
  end

  def update
    # Assign operation, and set username, same as email
    params[:profile].merge!({operation: 'update', username: profile_params[:email_address]})
    @profile.assign_attributes(profile_params)

    @tos = Tos.latest

    respond_to do |format|
      if @profile.valid? && @profile.remote_save(session[:lang])
        format.html { redirect_to profile_path, notice: t('profiles.notice.success_created') }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @profile.destroy
    respond_to do |format|
      format.html { redirect_to profiles_url, notice: t('profiles.notice.success_created') }
    end
  end

  def accounts
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @account_search = extract_object(:account_search) || AccountSearch.new
    @account_search.account_number = session[:accounts].first[:account_number] if session[:accounts]
    @account_search.postal_code = session[:postal_code]
  end

  def search_accounts
    @account_search = AccountSearch.new(account_search_params)

    respond_to do |format|
      if @account_search.valid?

        background_notice!(t('sessions.retrieving_info'))
        HardWorker.perform_async(session.id, :search_accounts, account_search_params)

        results = @account_search.search(account_search_params)
        session[:accounts] = results
        session[:postal_code] = account_search_params[:postal_code]
        # format.html { redirect_to profiles_accounts_path, notice: t("profiles.notice.accounts_found") }
        format.js { render 'pages/background_job' }
      else
        session.delete(:accounts)
        session.delete(:postal_code)
        format.html { render :accounts }
      end
    end
  end

  def link_accounts
    @offer = Offer.current_offer(offer_id: session[:offer_id], user_region: session[:user_region])
    @account_search = extract_object(:account_search) || AccountSearch.new(account_search_params)

    respond_to do |format|
      if @account_search.valid? && !account_search_params[:validate]
      
        background_notice!(t('sessions.retrieving_info'))
        HardWorker.perform_async(session.id, :link_accounts, account_search_params)
        format.js { render 'pages/background_job' }
      else
        format.json { render json: {name: @account_search.to_s.underscore, errors: @account_search.errors.messages } }
      end
    end    
  end

  def forgot_password
    @forgot_password = extract_object(:forgot_password) || ForgotPassword.new
  end

  def forgot_password_email
    @forgot_password = ForgotPassword.new(forgot_password_params)

    respond_to do |format|
      if @forgot_password.valid? && !forgot_password_params[:validate]
        
        background_notice!(t('profiles.checking_email'))
        HardWorker.perform_async(session.id, :forgot_password_email, forgot_password_params)

        format.js { render 'pages/background_job' }
      else
        format.json { render json: {name: @forgot_password.class.to_s.underscore, errors: @forgot_password.errors.messages } }
      end
    end
  end  

  def forgot_password_hint
    @forgot_password = extract_object(:forgot_password, false)
    redirect_to forgot_password_path unless @forgot_password
  end

  def forgot_password_answer
    @forgot_password = ForgotPassword.new(forgot_password_params)

    respond_to do |format|
      if @forgot_password.valid? && !forgot_password_params[:validate]

        background_notice!(t('profiles.checking_answer'))
        HardWorker.perform_async(session.id, :forgot_password_answer, forgot_password_params)

        format.js { render 'pages/background_job' }
      else
        format.json { render json: {name: @forgot_password.class.to_s.underscore, errors: @forgot_password.errors.messages } }
      end
    end
  end

  def change_password
    @change_password = extract_object(:change_password) || ChangePassword.new
  end

  def change_password_post
    @change_password = ChangePassword.new(change_password_params)

    respond_to do |format|
      if @change_password.valid?
        
        background_notice!(t('sessions.retrieving_info'))
        HardWorker.perform_async(session.id, :change_password, 
          change_password_params.merge({
            username: @current_session.username,
            password: @current_session.password,
            smtoken: @current_session.smtoken,
            smagentname: @current_session.smagentname,
            smenc: @current_session.smenc,
            smauthreason: @current_session.smauthreason
          })
        )

        format.js { render 'pages/background_job' }
      else
        session[:object] = { change_password: @change_password } 
        format.js { render js: "window.location = '#{change_password_path}'" }
      end
    end

  end

  def promo_code
    background_notice!(t('profiles.verifying_promo_code'))
    HardWorker.perform_async(session.id, :promo_code?, {code: params[:promo_code][:code], current_url: request.referer})
    respond_to do |format|
      format.js { render 'pages/background_job' }
    end
  end

  def promo_business
    redirect_to root_path unless session[:promo_code]
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profile
      @profile = @current_session.profile
    end

    def account_search_params
      params.require(:account_search).permit(:account_number, :postal_code, :first_name, :last_name, :birthdate, :account_pin, :search_type, :validate).symbolize_keys
    end

    def forgot_password_params
      params.require(:forgot_password).permit(:email_address, :password_hint, :password_answer, :validate).symbolize_keys
    end

    def change_password_params
      params.require(:change_password).permit(:new_password, :new_password_confirmation).symbolize_keys
    end

    def profile_params
      params.require(:profile).permit(:operation, :username, :password, :password_confirmation, :email_address, :email_address_confirmation, :phone, 
                                      :hint_question, :account_token, :tos, :tos_id, :tos_version, :postal_code, :birthdate, :first_name, :last_name, 
                                      :paperless_billing, :lang_pref, :account_number, :postal_code, :birthdate, :account_pin, :question, :answer, :email_opt_in, :nhl_opt_in, :validate).symbolize_keys
    end
end
