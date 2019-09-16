class AccountSearch < Portal
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :account_number, :postal_code, :first_name, :last_name, :birthdate, :account_pin, :search_type, :account_number_on_bill

  validates_presence_of :postal_code
  validates_format_of :postal_code, with: /\A([a-zA-Z]\d[a-zA-z]( )?\d[a-zA-Z]\d)\z/
  validates_presence_of :account_number, :if => -> { search_type.to_s != 'advanced' }
  validates_format_of :account_number, with: /\A(\d{9}|\d{12}|\d{13})\z/, message: :invalid
  validates_presence_of :first_name, :last_name, :birthdate, :if => -> { search_type.to_s == 'advanced' }


  def search
    begin
      result = api_client.account_lookup(attributes)
    rescue GodzillaApi::Exception => e
      api_error = e.error
      self.errors[:base] << api_error[lang.to_sym]
      return false
    end
    if result[:token_found]
      background_params[:redirect] = profiles_accounts_path
      background_params[:notice_type] = :notice
      background_params[:notice] = t("profiles.notice.accounts_found")
      result[:account]
    else
      self.errors.add(:base, :not_found)
      false
    end
  end

  def link_accounts
    begin
      result = api_client.account_lookup(account_number: account_number, postal_code: postal_code)
      accounts = result[:account] if result[:number_of_results].to_i > 0
      unless accounts
        self.errors.add(:base, :not_found)
        background_params[:account_linking] = 'failed'
        return false
      end
      account = accounts.select { |a| a[:account_number].to_s == account_number }.try(:first)
      unless account
        self.errors.add(:base, :not_found)
        background_params[:account_linking] = 'failed'
        return false
      end
      api_client.profile_update(attributes.merge({operation: 'edit', account_token: account[:account_token]}))
      profile = Portal.current_session.profile
      profile.account_token = account[:account_token]
     
      # Update entitlements and accounts
      result = api_client.get_entitlement
      profile.entitlement = result[:entitlement]

      profile.delete_accounts
      result[:accounts].each do |a|
        profile.accounts << Account.create(a) if a[:account_token]
      end

      profile.save

      if profile.eligible?
        background_params[:account_linking] = 'eligible'
        background_params[:redirect] = profiles_path
      elsif profile.cannot_buy?
        # Shomi: Linked account not compatible, redirect to profiles so users can link another acct
        background_params[:account_linking] = 'cannot_buy'
        background_params[:redirect] = profiles_path
      else
        background_params[:account_linking] = 'ineligible'
        background_params[:redirect] = orders_path
      end
      background_params[:notice_type] = :notice
      background_params[:notice] = I18n.t("profiles.notice.success_linked")
    rescue GodzillaApi::Exception => e
      api_error = e.error
      self.errors[:base] << api_error[lang.to_sym]
      background_params[:account_linking] = 'failed'
      background_params[:redirect] = profiles_accounts_path
      background_params[:notice_type] = :alert
      background_params[:notice] = I18n.t("profiles.notice.linking_failed")
      return false
    end
    true
  end
end
