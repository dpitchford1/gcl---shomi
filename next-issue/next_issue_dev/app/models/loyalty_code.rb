class LoyaltyCode < Portal
  attribute :code
  attribute :code_type
  attribute :membership_type
  attribute :valid_for_product
  attribute :offer_logo_basic_en
  attribute :offer_logo_premium_en
  attribute :offer_logo_basic_fr
  attribute :offer_logo_premium_fr
  attribute :valid_for_basic
  attribute :valid_for_premium

  index :code
  
  def self.check(params)

    code = params[:code]
    lang = params[:lang]
    I18n.locale = lang

    loyalty_code = LoyaltyCode.find(code: code).first
    unless loyalty_code
      loyalty_code = LoyaltyCode.new(params)
      begin
        result_b = loyalty_code.api_client.loyalty_code?(code+"b")
        loyalty_code.valid_for_basic = loyalty_code.resolve_validation_type(loyalty_code, result_b)
        
        result_p = loyalty_code.api_client.loyalty_code?(code+"p")
        loyalty_code.valid_for_premium = loyalty_code.resolve_validation_type(loyalty_code, result_p)
      rescue GodzillaApi::Exception => e
        loyalty_code.code_type = 'invalid'
        loyalty_code.valid_for_product = 'none'
        loyalty_code.errors.add(:base, e.error["msg_en"])
      end
      loyalty_code.save
    else
      loyalty_code.current_url = params[:current_url]
    end
    loyalty_code
  end

  def resolve_validation_type(loyalty_code, result)
    if loyalty_code.code_type != "valid"
      loyalty_code.code_type = result.fetch(:loyalty_info, {}).fetch(:is_valid, false) ? "valid" : "invalid"

      puts "LOYALTY CODE TYPE: #{loyalty_code.code_type}"
      loyalty_code.valid_for_product = result[:valid_for_product]

      if loyalty_code.code.match(/air/i)
        loyalty_code.membership_type = 'Air Miles'
      elsif loyalty_code.code.match(/sce/i)
        loyalty_code.membership_type = 'Scene'
      elsif loyalty_code.code.match(/aer/i)
        loyalty_code.membership_type = 'Aeroplan'
      elsif loyalty_code.code.match(/charger/i)
        loyalty_code.membership_type = 'Charger'
      elsif loyalty_code.code.match(/via/i)
        loyalty_code.membership_type = 'VIA Préférence'
      else
        loyalty_code.membership_type = ''
      end
    end

    return "valid" == loyalty_code.code_type
  end

  def valid?
    code_type_check = code_type =~ /^(invalid)$/ ? false : true
    valid_for_product_check = valid_for_product.downcase == ENV["APP_NAME"]
    return code_type_check && valid_for_product_check
    super
  end

  def validation_type
    if code.to_s.match(/amex/i)
      'amex'
    elsif code.to_s.match(/mastercard/i)
      'mastercard'
    elsif code.to_s.match(/visa/i)
      'visa'
    else
      'any'
    end
  end

  def display_loyalty_for_offer?(offer=nil)
    return false if offer.nil?

    if offer.basic?
      valid_for_basic
    else
      valid_for_premium
    end
  end

  def allow_membership_number?
    membership_type != 'Charger'
  end

  # if language used doesn't return anything, try returning other language logo
  def offer_logo_basic(lang='en')
    result = try("offer_logo_basic_#{lang}")
    result = lang.to_s == 'en' ? offer_logo_basic_fr : offer_logo_basic_en if result.blank?
    result
  end

  def offer_logo_premium(lang='en')
    result = try("offer_logo_premium_#{lang}")
    result = lang.to_s == 'en' ? offer_logo_premium_fr : offer_logo_premium_en if result.blank?
    result
  end
end