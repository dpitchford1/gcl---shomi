class Order < Portal
  attr_accessor :operation, :credit_card, :zuora_timestamp, :zuora_token, :offer_type

  attribute :billing_option

  attribute :account_summary_token
  attribute :province
  attribute :street
  attribute :address2
  attribute :postal_code
  attribute :city
  attribute :first_name
  attribute :last_name
  attribute :full_name

  attribute :cc_token
  attribute :masked_cc
  attribute :cc_type
  attribute :rogers_account_token
  attribute :ctn
  attribute :can
  attribute :optin_email

  attribute :promo_code
  attribute :code_type
  attribute :desc

  attribute :auto_renew
  attribute :phone_number
  attribute :birthdate, Type::Date

  attribute :order_id # Rogers order id
  attribute :offer_id # Rogers offer id
  attribute :price
  attribute :taxes
  attribute :frequency
  attribute :desc_en
  attribute :desc_fr

  attribute :product #phase 2 attribute
  attribute :loyalty_code
  attribute :membership_number
  attribute :membership_type
  attribute :cancellation_reason
  attribute :optin
  attribute :optin_account_token
  attribute :lang # language preferences for user
  attribute :campaign_identifier
  attribute :term_type

  attribute :nhl_opt_in
  attribute :email_opt_in

  index :order_id
  index :offer_id
  index :rogers_account_token
  index :cc_token

  delegate :can_upgrade?, :basic?, :premium?, :description, to: :offer, allow_nil: true
  delegate :price, to: :offer, allow_nil: true, prefix: true

  reference :profile, :Profile

  encrypted :billing_option ,:province ,:street ,:postal_code ,:city ,:first_name ,:last_name ,:full_name ,:masked_cc ,:cc_type ,:ctn ,:can ,:optin_email ,:promo_code ,:auto_renew ,:phone_number ,:price ,:taxes ,:frequency ,:desc_en ,:desc_fr, :optin, :optin_account_token, :campaign_identifier, :account_summary_token

  validates_presence_of :offer_id
  validates_presence_of :birthdate,  :if => -> { !skip_birthdate_validation? }
  validates_presence_of :first_name, :last_name, :street, :city, :province, :postal_code,  :if => -> { billing_option == 'free' }
  validates_presence_of :rogers_account_token,  :if => -> { billing_option == 'rogersbill' && !skip_rogers_account_token_validation? }
  validates_presence_of :phone_number,  :if => -> { ['free', 'rogersbill'].include?(billing_option) && !skip_phone_number_validation? }
  validates_format_of :phone_number, with: /\A\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z/, allow_blank: true, :if => -> { !skip_phone_number_validation? }
  validates_format_of :postal_code, with: /\A([a-zA-Z]\d[a-zA-z]( )?\d[a-zA-Z]\d)\z/, :if => -> { ['free', 'cc'].include?(billing_option) }
  validates_acceptance_of :tos
  validates_acceptance_of :tos2, :if => -> { ENV['APP_NAME'] == 'shomi' }
  validates_presence_of :cancellation_reason, if: -> { billing_option == 'cancel' }
  validate :membership_number_is_valid_length

  def get_membership_length
    if membership_type == 'Air Miles'
      11
    elsif membership_type == 'Scene'
      16
    elsif membership_type == 'VIA Préférence'
      7
    end
  end

  def membership_number_is_valid_length
    if !membership_number.to_s.match(/\A\d+\z/) || membership_number.length < 7 || (get_membership_length && membership_number.length != get_membership_length)
      if !membership_number.blank? && membership_number.downcase != 'none'
        errors.add(:membership_number, I18n.t('errors.attributes.membership_number.too_short'))
      end
    end
  end
  
  # call order.skip_birthdate_validation! to avoid requiring birthdate
  %w(birthdate phone_number rogers_account_token).each do |field|
    define_method "skip_#{field}_validation?" do
      self.instance_variable_get("@skip_#{field}_validation") || false
    end

    define_method "skip_#{field}_validation!" do
      self.instance_variable_set("@skip_#{field}_validation", true)
    end
  end

  def initialize(attributes={})
    super
    @zuora_timestamp = DateTime.now.strftime('%Q')
    @zuora_token = SecureRandom.hex
    begin
      I18n.locale = lang
    rescue 
    end
  end

  def province!
    if rogers_account_token
      account = Account.find(account_token: rogers_account_token).first
      self.province = account.billing_address_province if account
    end
  end

  def offer
    Offer.find(offer_id: offer_id).first
  end

  def taxes
    return nil unless province && CONFIG[:pst][province.downcase.to_sym]
    rate = (CONFIG[:pst][province.downcase.to_sym] + CONFIG[:gst]).to_f/100
    (price.to_f * rate).round(2)
  end

  def total
    (taxes.to_f + price.to_f).round(2)
  end

  # Has to be instance method to access api_client
  def history
    api_client.get_orders
  end

  def change_offer(params={})
    begin
      result = api_client.change_offer(offer_id: offer_id, existing_offer_type: params[:existing_offer_type], user_is_on_redemption: params[:user_is_on_redemption], term_type: params[:term_type])

      success_message = ENV['basic_offer_id'] == offer_id ? I18n.t('orders.update_offer.basic') : I18n.t('orders.update_offer.premium')
      background_params[:redirect], background_params[:notice_type], background_params[:notice] = *resulting_redirection(result, profiles_path, success_message)
      return false if background_params[:notice_type] == :alert
    rescue GodzillaApi::Exception => e
      background_params[:notice] = e.error[lang.to_sym]
      background_params[:notice_type] = :alert
      background_params[:redirect] = profiles_path
      background_params[:developer_message] = e.error[:dev]
      return false
    end
    true
  end

  def remote_save(ip_address=nil, user_is_active=false, user_is_on_redemption=false, add_order_errors_to_notice=false)
    # Verify valid account
    if rogers_account_token
      account = Portal.current_session.profile.get_account(rogers_account_token)
      rogers_account_token = account.try(:account_token)
    end

    begin
      order_parameters = self.attributes.merge({operation: self.operation, user_is_active: user_is_active, user_is_on_redemption: user_is_on_redemption})
      result = api_client.create_order(order_parameters)
      self.order_id = result[:order_id]
      self.phone_number = nil # Security requirement
      save

      background_params[:redirect], background_params[:notice_type], background_params[:notice] = *redirect
      background_params[:order_confirmation] = "#{billing_option} success"

      Portal.email_capture(profile.email_address, profile.entitlement ? profile.entitlement[:level] : "unknown", api_client.guid, self.email_opt_in.to_s.to_i, self.nhl_opt_in.to_s.to_i)

      # Delete after some delay
      Order.delay_for(10.minutes).delete(self.id)
    rescue GodzillaApi::Exception => e
      api_error = e.error[lang.to_sym]
      if add_order_errors_to_notice
        background_params[:notice] = api_error
        background_params[:notice_type] = :alert
      else
        self.errors.add(:base, api_error)
        credit_card.errors.add(:base, api_error) if billing_option == 'cc'
      end
      background_params[:order_confirmation] = "#{billing_option} failed"
      background_params[:redirect] = redirect.first
      background_params[:developer_message] = e.error[:dev].to_s.to_valid_utf8

      api_client.log_godzilla_exception({api_call: '/order', parameters: order_parameters, developer_message: "e.error: #{e.error.inspect}"})
      return false
    end
    true
  end

  def refresh_entitlements(ip_address=nil)
    profile = Portal.current_session.profile

    begin
      entitlement_result = api_client.get_entitlement(ip_address: ip_address)

      if entitlement_result[:entitlement]
        #load promo code history into entitlements if required
        if ENV["user_promo_history"]
          promo_code_history = api_client.get_promo_code_history
          if promo_code_history[:history]
            entitlement_result[:entitlement][:promo_code_history] = promo_code_history[:history]
          end
        end

        profile.entitlement = entitlement_result[:entitlement] if entitlement_result[:entitlement]
      end

      profile.save
    rescue 
      return false
    end
    true
  end

  def refresh_order_history(ip_address=nil)
    profile = Portal.current_session.profile

    begin
      #load user orders if required
      if ENV["user_orders"]
        user_orders_result = api_client.get_orders

        if user_orders_result[:user_orders]
          profile.delete_user_orders
          user_orders_result[:user_orders].each do |a|
            profile.user_orders << UserOrder.create(a) if a[:order_id]
          end
        end
      end

      profile.save
    rescue
      return false
    end
    true
  end

  def apply_promo_code
    begin
      apply_promo_code_result = api_client.apply_promo_code(self.attributes)

      background_params[:redirect], background_params[:notice_type], background_params[:notice] = *resulting_redirection(apply_promo_code_result, profiles_path, I18n.t('cancel_order.successfully_applied_promo'))
      return false if background_params[:notice_type] == :alert
    rescue GodzillaApi::Exception => e
      background_params[:redirect], background_params[:notice_type], background_params[:notice] = [profiles_path, :alert, e.error[lang.to_sym]]
      background_params[:developer_message] = e.error[:dev]
      return false
    end
    true
  end

  def resulting_redirection(result, redirect_path, success='')
    if result.nil?
      [redirect_path, :alert, I18n.t('pages.background.service_unavailable')]
    elsif result[:result_code] == 0
      [redirect_path, :notice, success]
    else
      [redirect_path, :alert, result["msg_#{lang}"]]
    end
  end

   def redirect
      if errors.blank?
        if ENV['APP_NAME'] == 'nextissue' && billing_option == 'free'
          [profiles_path, :notice, I18n.t('orders.notice.applied_promo_code_success')]
        else
          [profiles_path(order_id: id), :notice, I18n.t('orders.notice.success')]
        end
      elsif billing_option == 'cc'
        [new_order_path(order: { billing_option: 'cc'}), nil, nil]
      elsif billing_option == 'free'
        [promo_contact_path, nil, nil]
      else
        [new_order_path(order: { billing_option: billing_option}), nil, nil]
      end    
  end

  def self.delete(id)
    Order[id].try(:delete)
  end

  def zuora_iframe_url
    "#{CONFIG[:zuora_api_endpoint]}/apps/PublicHostedPage.do?method=requestPage&id=#{ENV['zuora_page_id']}&tenantId=#{ENV['zuora_tenant_id']}&timestamp=#{@zuora_timestamp}&token=#{@zuora_token}&signature=#{zuora_signature}".html_safe
  end

  def zuora_signature
    Base64.encode64(Digest::MD5.hexdigest("id=#{ENV['zuora_page_id']}&tenantId=#{ENV['zuora_tenant_id']}&timestamp=#{@zuora_timestamp}&token=#{@zuora_token}#{ENV['zuora_secret_key']}")).rstrip
  end

  def cancel_order(billing_cycle_end_date=nil)
    begin
      result = api_client.cancel_order(self.attributes)

      profile = Portal.current_session.profile
      # get_entitlement method is not reliable right after submitting an order. Instead we write the entitlement level manually ourselves.
      profile.entitlement = {:entitlement => 'none', :level => "cancelled", :code => "0"}

      #reload user orders if required
      if ENV["user_orders"]
        profile.delete_user_orders
        user_orders_result = api_client.get_orders
        if user_orders_result[:user_orders]
          user_orders_result[:user_orders].each do |a|
            profile.user_orders << UserOrder.create(a) if a[:order_id]
          end
        end
      end
      profile.save


      background_params[:redirect], background_params[:notice_type] = [profiles_path(cancel_promo_code: true), :notice]
      if Admin::FeatureFlag.feature_flag(:cancel_survey)
        billing_cycle_end_date = Date.parse(billing_cycle_end_date).strftime('%d/%m/%Y') rescue ''
        background_params[:notice] = I18n.t('orders.cancel_survey_subscription', date: billing_cycle_end_date)
      else
        background_params[:notice] = I18n.t('orders.cancel_subscription')
      end
    rescue GodzillaApi::Exception => e
      background_params[:notice] = e.error[lang.to_sym]
      background_params[:notice_type] = :alert
      background_params[:redirect] = profiles_path
      background_params[:developer_message] = e.error[:dev]

      api_client.log_godzilla_exception({api_call: '/cancelorder', parameters: self.attributes, developer_message: "e.error: #{e.error.inspect}"})
      return false
    end
    true
  end
end