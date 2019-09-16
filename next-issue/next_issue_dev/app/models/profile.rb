class Profile < Portal

  attr_accessor :password, :operation


  attribute :user_id
  attribute :username
  attribute :first_name
  attribute :last_name
  attribute :email_address
  attribute :phone
  attribute :language
  attribute :account_token
  # Account summary token is used to update the profile with (not to be confused with the account's account_token)
  attribute :account_summary_token
  attribute :tos_id
  attribute :tos_version
  attribute :postal_code
  attribute :birthdate
  attribute :first_name
  attribute :last_name
  attribute :paperless_billing
  attribute :lang_pref
  attribute :question
  attribute :answer
  attribute :entitlement, Type::Hash
  attribute :email_opt_in
  attribute :nhl_opt_in

  attribute :login_attempts, Type::Integer
  attribute :last_login_attempt, Type::Time

  index :username
  index :email_address
  index :phone

  # unique :username
  # unique :email_address
  set :accounts, :Account
  set :user_orders, :UserOrder
  collection :orders, :Order

  encrypted :first_name, :last_name, :language, :account_token, :account_summary_token, :tos_id, :tos_version, :postal_code, :birthdate, :first_name, :last_name, :paperless_billing, :lang_pref, :question, :answer

  validates_uniqueness_of :username, :email_address, on: :create
  validates_confirmation_of :email_address, :password
  validates_presence_of :email_address, :lang_pref, :password, :question, :answer
  validates_format_of :email_address, with: RubyRegex::Email
  validates_acceptance_of :tos
  validates_length_of :answer, maximum: 40
  validates_length_of :password, minimum: 7, maximum: 16
  validates_format_of :password, with: /\A(?=.*[0-9])(?=.*[a-zA-Z])[a-zA-Z0-9]+\z/
  validates_format_of :phone, with: /\A\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z/, allow_blank: true

  
  def remote_save
    begin
      tos = Tos.latest
      tos_id = tos.tos_id
      tos_version = tos.tos_version
    rescue
    end

    begin
      profile_params = self.attributes.merge(password: self.password, operation: self.operation)
      result = api_client.profile_update(profile_params)

      background_params[:redirect] = profiles_path
      if result[:result_code] == 0
        self.background_params[:notice_type] = :notice
        self.background_params[:notice] = I18n.t('profiles.notice.successfully_updated')
      else
        self.background_params[:notice_type] = :alert
        self.background_params[:notice] = I18n.t('pages.background.service_unavailable')
      end

      self.phone = nil # Security requirement
      save
    rescue GodzillaApi::Exception => e
      api_error = e.error
      self.errors[:base] << api_error[lang.to_sym]

      #set background_params for redirect for update profile situation
      self.background_params[:redirect] = profiles_path
      self.background_params[:notice_type] = :alert
      self.background_params[:notice] =  api_error[lang.to_sym]
      self.background_params[:developer_message] = api_error[:dev]

      safer_params = profile_params.dup
      safer_params.delete(:api_client)
      safer_params = api_client.output_safe(safer_params)
      api_client.log_godzilla_exception({api_call: '/profile_update', parameters: safer_params, developer_message: "e.error: #{e.error.inspect}"})
      return false
    end
    true
  end

  def create_and_login
    if remote_save
      Session.new(self.attributes.merge(password: self.password))
    else
      false
    end
  end
  
  def delete_accounts
    accounts.each { |a| a.delete; accounts.delete(a) }
  end

  def delete_user_orders
    # a.delete to destroy the user order record, and user_orders.delete(a) to delete the profile object's reference to that user order
    user_orders.each { |a| a.delete; user_orders.delete(a) }
  end

  def eligible?
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement && ['promo', 'purchased', 'eligible', 'promotopup'].include?(entitlement[:level]) ? true  : false
  end

  def has_redemption?
    PromoCode::REDEMPTION_CODE_TYPES.include?(promotion_type.to_s.downcase) ? true  : false
  end

  def has_discount?
    promotion_type.to_s.downcase == 'discount' ? true  : false
  end

  def has_extended_free_trial?
    promotion_type.to_s.downcase == 'extendedtrial' ? true  : false
  end

  def purchased?
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement && ['purchased'].include?(entitlement[:level]) ? true  : false
  end

  def cannot_buy?
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement && ENV['cannot_buy_levels'].split(',').include?(entitlement[:level]) ? true  : false
  end

  def product
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:entitlement].upcase : ENV['APP_NAME'].upcase
  end

  def level
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:level].to_s : nil
  end

  def code
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:code].to_i : nil
  end

  def optin
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:optin] : nil
  end

  def optin_account_token
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:optin_account_token] : nil
  end

  def user_has_billing_info?
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:user_has_billing_info] : nil
  end

  def promo_code_history
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement ? entitlement[:promo_code_history] : nil
  end

  def has_promo_code_type_in_history?(type='discount')
    if promo_code_history
      promo_code_history.each do |record|
        return true if record['promo_type'].to_s == type
      end
    else
      false
    end
  end

  def has_promo_code_in_history?(code)
    if promo_code_history && code.present?
      promo_code_history.each do |record|
        return true if record['promo_code'].to_s == code
      end
    end
    false
  end

  def loyalty_type
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    # return loyalty_type by string after save, or by symbol from api entitlement result
    if entitlement && entitlement.fetch(:loyalty_data, {}).fetch('loyalty_type', nil)
      entitlement[:loyalty_data]['loyalty_type']
    elsif entitlement && entitlement.fetch(:loyalty_data, {}).fetch(:loyalty_type, nil)
      entitlement[:loyalty_data][:loyalty_type]
    else
      nil
    end
  end

  def loyalty_membership_number
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:loyalty_data, {}).fetch('loyalty_membership_number', nil)
      entitlement[:loyalty_data]['loyalty_membership_number']
    elsif entitlement && entitlement.fetch(:loyalty_data, {}).fetch(:loyalty_membership_number, nil)
      entitlement[:loyalty_data][:loyalty_membership_number]
    else
      nil
    end
  end

  def loyalty_redeemed
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:loyalty_data, {}).fetch('loyalty_redeemed', nil)
      entitlement[:loyalty_data]['loyalty_redeemed']
    elsif entitlement && entitlement.fetch(:loyalty_data, {}).fetch(:loyalty_redeemed, nil)
      entitlement[:loyalty_data][:loyalty_redeemed]
    else
      nil
    end
  end

  def promotion_type
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:promo_data, {}).fetch('promo_type', nil)
      entitlement[:promo_data]['promo_type']
    elsif entitlement && entitlement.fetch(:promo_data, {}).fetch(:promo_type, nil)
      entitlement[:promo_data][:promo_type]
    else
      nil
    end
  end

  def promotion_desc
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:promo_data, {}).fetch('promo_desc', nil)
      entitlement[:promo_data]['promo_desc']
    elsif entitlement && entitlement.fetch(:promo_data, {}).fetch(:promo_desc, nil)
      entitlement[:promo_data][:promo_desc]
    else
      nil
    end
  end

  def promotion_description
    I18n.t("promo_code.description.#{promotion_code.to_s.downcase}", default: promotion_desc)
  end

  def promotion_code
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:promo_data, {}).fetch('promo_code', nil)
      entitlement[:promo_data]['promo_code']
    elsif entitlement && entitlement.fetch(:promo_data, {}).fetch(:promo_code, nil)
      entitlement[:promo_data][:promo_code]
    else
      nil
    end
  end

  def promotion_expiration
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:promo_data, {}).fetch('expiry_date', nil)
      entitlement[:promo_data]['expiry_date']
    elsif entitlement && entitlement.fetch(:promo_data, {}).fetch(:promo_code, nil)
      entitlement[:promo_data][:expiry_date]
    else
      nil
    end
  end

  def promotion_expiry_date
    Date.parse(promotion_expiration, ENV['entitlement_expiry_date_format']) if promotion_expiration.present?
  end

  def promotion_valid_tiers
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch(:promo_data, {}).fetch('valid_tiers', nil)
      entitlement[:promo_data]['valid_tiers']
    elsif entitlement && entitlement.fetch(:promo_data, {}).fetch(:valid_tiers, nil)
      entitlement[:promo_data][:valid_tiers]
    else
      nil
    end
  end

  def promotion_valid_for?(type)
    promotion_valid_tiers.blank? || promotion_valid_tiers.to_s.gsub(/\s/, '').downcase.split(',').include?(type.to_s.downcase)
  end

  # for simple_form
  def collection
    accounts.map { |a| [a.account_desc, a.account_token] }
  end

  def get_account(account_desc)
    accounts.find(account_desc: account_desc).first
  end

  def get_account_by_token(account_token)
    accounts.find(account_token: account_token).first
  end

  def self.email_check(params)
    api_client = params[:api_client]
    api_client.profile_check(params[:email_address])
  end

  def latest_order
    user_orders.first
  end

  def allowed_to_use_promo_code?
    return true if promo_code_history.nil?
    # disable promo code if the history contains a discount or extended free trial 
    promo_code_history.each do |h|
      return false if ['discount','extendedtrial'].include?(h.fetch('promo_type', '').to_s.downcase)
    end

    #or if the user is on a term subcription
    return false if self.promotion_type && (self.promotion_type.downcase == "termsubscription")
    true
  end

  def disable_loyalty?
    # if there is a loyalty type in entitlements & the user has cancelled their subscription, then disable loyalty on form page
    loyalty_type.to_s.length > 0 && (Admin::FeatureFlag.feature_flag(:enable_updating_loyalty) || latest_order.status.to_s.downcase != 'cancelled')
  end

  def on_top_up?
    level == 'promotopup'
  end

  def can_top_up?
    has_redemption? && basic?
  end

  def existing_offer_type
    if basic?
      return "Basic"
    elsif premium?
      return "Premium"
    end
  end

  def term_type
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    if entitlement && entitlement.fetch('term_type', nil)
      entitlement['term_type']
    elsif entitlement && entitlement.fetch(:term_type, nil)
      entitlement[:term_type]
    else
      nil
    end
  end

  def basic?
    code == 0
  end

  def premium?
    code == 1
  end

  # Catch feature flag fake user states and parse options to setup that profile state
  # * use mock_profile_user admin flag to define a comma delimited profile_states option which specifies which state methods to use
  # * use seed_default_profile_states rake tasks to define default profile state address/user_orders/entitlements/promo_data/promo_code_history which are parsed below
  def method_missing(m, *args, &block)
    if ENV['allow_profile_user_states']
      if m.to_s == 'rogers_user_state'
        if accounts.empty?
          [{:account_token=>"CAN:123456|PROVINCE:ON|TYPE:Cable|FIRSTNAME:JON|LASTNAME:DOE", :account_desc_en=>"54321(Cable)", :billing_address_province=>"ON", :billing_address_postal_code=>"A1B1C1", :account_desc_fr=>"54321(Cable)", :account_type_en=>"SS", :account_type_fr=>"SS"}, {:account_token=>"BAN:123456|CTN:12345|PROVINCE:ON|TYPE:Rogers Wireless|FIRSTNAME:JON|LASTNAME:DOE", :account_desc_en=>"54321(Rogers Wireless)", :billing_address_province=>"ON", :billing_address_postal_code=>"A1B1C1", :account_desc_fr=>"54321(Rogers Wireless)", :account_type_en=>"Rogers Wireless", :account_type_fr=>"Rogers Wireless"}].each do |a|
            accounts << Account.create(a)
          end
        end

        entitlement
      else
        flag_state = Admin::FeatureFlag.find(title: m).first
        if flag_state.nil?
          super # feature flag 'm' not defined, use original method missing
        elsif flag_state.options
          if ENV["user_orders"]
            user_address_info = JSON.parse "{#{flag_state.options['address'].to_s}}"

            flag_state.options['user_orders'].split('-|-').each do |order|
              user_orders << UserOrder.create(JSON.parse("{#{order}}").merge(user_address_info))
            end
          end

          if entitlement
            promo_code_history = []

            if ENV["user_promo_history"]
              flag_state.options['promo_code_history'].split('-|-').each do |history|
                promo_code_history << JSON.parse("{#{history}}")
              end
            end

            entitlement.merge(JSON.parse("{#{flag_state.options['entitlement'].to_s}}")).merge({ promo_data: JSON.parse("{#{flag_state.options['promo_data'].to_s}}") }).merge({ promo_code_history: promo_code_history})
          end
        end
      end
    else
      super # allow_profile_user_states is disabled, so just use method missing
    end
  end
end
