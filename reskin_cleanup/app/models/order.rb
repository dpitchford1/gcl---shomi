class Order < Portal
  attr_accessor :operation, :credit_card, :zuora_timestamp, :zuora_token
 
  attribute :billing_option
  
  attribute :province
  attribute :street
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
  attribute :nhl_opt_in
  attribute :email_opt_in


  index :order_id
  index :offer_id
  index :rogers_account_token
  index :cc_token

  reference :profile, :Profile

  encrypted :billing_option ,:province ,:street ,:postal_code ,:city ,:first_name ,:last_name ,:full_name ,:masked_cc ,:cc_type ,:ctn ,:can ,:optin_email ,:promo_code ,:auto_renew ,:phone_number ,:price ,:taxes ,:frequency ,:desc_en ,:desc_fr

  validates_presence_of :offer_id, :birthdate
  validates_presence_of :first_name, :last_name, :street, :city, :province, :postal_code,  :if => -> { billing_option == 'free' }
  validates_presence_of :rogers_account_token, :phone_number,  :if => -> { billing_option == 'rogersbill' }
  validates_format_of :postal_code, with: /\A([a-zA-Z]\d[a-zA-z]( )?\d[a-zA-Z]\d)\z/, :if => -> { ['free', 'cc'].include?(billing_option) }
  validates_format_of :phone_number, with: /\A\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z/
  validates_acceptance_of :tos
  validates_acceptance_of :tos2, :if => -> { ENV['APP_NAME'] == 'shomi' }


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

  def remote_save
    # Verify valid account
    if rogers_account_token
      account = Portal.current_session.profile.get_account(rogers_account_token)
      rogers_account_token = account.try(:account_token)
    end

    begin
      result = api_client.create_order(self.attributes.merge(operation: self.operation))
      self.order_id = result[:order_id]
      self.phone_number = nil # Security requirement
      save

      profile = Portal.current_session.profile
      # entitlement_result = api_client.get_entitlement(product: ENV['product_list'] ? JSON.parse(ENV['product_list']) : params[:product])
      # profile.entitlement = entitlement_result[:entitlement]
      offer = Offer.find(offer_id: self.offer_id).try(:first)
      profile.entitlement = {:entitlement => offer.try(:product_code) || ENV['APP_NAME'], :level => "purchased", :code => "0"}

      profile.save

      background_params[:redirect], background_params[:notice_type], background_params[:notice] = *redirect
      background_params[:order_confirmation] = "#{billing_option} success"

      Portal.email_capture(profile.email_address, profile.entitlement ? profile.entitlement[:level] : "unknown", api_client.guid, self.email_opt_in.to_s.to_i, self.nhl_opt_in.to_s.to_i)

      # Delete after some delay
      Order.delay_for(10.minutes).delete(self.id)
    rescue GodzillaApi::Exception => e
      api_error = e.error
      self.errors.add(:base, api_error[lang.to_sym])
      credit_card.errors.add(:base, api_error[lang.to_sym]) if billing_option == 'cc'
      background_params[:order_confirmation] = "#{billing_option} failed"
      background_params[:redirect] = redirect.first
      return false
    end
    true
  end

  def redirect
      if errors.blank?
        [profiles_path(order_id: id), :notice, I18n.t('orders.notice.success')]
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

end