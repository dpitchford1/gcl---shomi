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
  collection :orders, :Order

  encrypted :first_name, :last_name, :language, :account_token, :tos_id, :tos_version, :postal_code, :birthdate, :first_name, :last_name, :paperless_billing, :lang_pref, :question, :answer

  validates_uniqueness_of :username, :email_address, on: :create
  validates_confirmation_of :email_address, :password
  validates_presence_of :email_address, :password, :lang_pref, :question, :answer
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
      result = api_client.profile_update(self.attributes.merge(password: self.password, operation: self.operation))
      self.phone = nil # Security requirement
      save
    rescue GodzillaApi::Exception => e
      api_error = e.error
      self.errors[:base] << api_error[lang.to_sym]
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

  def eligible?
    entitlement = self.entitlement.symbolize_keys if self.entitlement
    entitlement && ['purchased', 'eligible'].include?(entitlement[:level]) ? true  : false
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
    begin
      result = api_client.profile_check(params[:email_address])
    rescue GodzillaApi::Exception => e
      result = {profile_found: false, error: e.error["msg_en"]}
    end
    result
  end
end
