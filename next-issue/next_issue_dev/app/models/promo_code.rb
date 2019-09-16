class PromoCode < Portal
  REDEMPTION_CODE_TYPES = ['termsubscription']
  attribute :code
  attribute :code_type
  attribute :valid_offers
  attribute :valid_for_product
  attribute :promo_offer_id
  attribute :code_value_percentage
  attribute :code_value_amount
  attribute :description
  attribute :desc_en
  attribute :desc_fr
  attribute :image_url

  index :code

  def self.check(params)

    code = params[:code]
    lang = params[:lang]
    I18n.locale = lang
    
    promo_code = PromoCode.find(code: code).first if ENV["APP_NAME"] != "nextissue"

    unless promo_code
      promo_code = PromoCode.new(params)
      begin
        result = promo_code.api_client.promo_code?(code)
        promo_code.valid_offers = result[:valid_tiers].to_s.gsub(/\s/, '').downcase.split(',')
        promo_code.code_type = result[:code_type].to_s
        promo_code.description = result[:desc].to_s

        nextissue_vfp = ["termsubscription", "extendedtrial", "discount"].include?(promo_code.code_type) ? "nextissue" : "notnextissue" #hack because valid_for_product doesn't work with nextissue
        promo_code.valid_for_product = result[:valid_for_product] ? result[:valid_for_product].to_s.downcase : nextissue_vfp
      rescue GodzillaApi::Exception => e
        # Result code of 2 indicates expired promo code (other exceptions considered invalid)
        promo_code.code_type = if e.try(:error) && !e.error.fetch(:result).nil? && e.error[:result].fetch(:result_code) == 2
                                 'expired'
                               else
                                 'invalid'
                               end
        promo_code.valid_for_product = 'none'
        promo_code.errors.add(:base, e.error[:en])
        promo_code.background_params[:developer_message] = e.error[:dev]
      end
      promo_code.save #if ENV["APP_NAME"] != "nextissue"
    else
      promo_code.current_url = params[:current_url]
    end

    if promo_code.valid_for_params?(params)
      promo_code.background_params[:promo_code] = promo_code
    else
      promo_code.background_params[:promo_code] = nil
    end
    promo_code.background_params[:promo_code_invalid] = promo_code.code_type

    promo_code.background_params[:redirect], promo_code.background_params[:notice_type], promo_code.background_params[:notice] =  *promo_code.redirect(params)
    promo_code
  end

  def valid_for_params?(params={})
    if is_redemption?
      # valid and redemption field
      valid? && params[:validate_redemption_only] == 'true'
    elsif is_etf?
      # valid and coupon field and non-eligible user
      valid? && params[:validate_redemption_only] != 'true' && !params[:user_is_active]
    else
      # valid and coupon field
      valid? && params[:validate_redemption_only] != 'true'
    end
  end

  def valid?
    code_type_check = code_type =~ /^(invalid|used|expired)$/ ? false : true #check to see if code type is invalid
    valid_for_product_check = valid_for_product.to_s.downcase == ENV["APP_NAME"] #check to see if the promo code is for the current application
    return code_type_check && valid_for_product_check
    super
  end

  def login_redirect
    l_redirect, notice_type, notice = redirect({}, true)
    return l_redirect
  end

  def redirect(params={}, on_login = false)
    if !on_login && !valid_for_params?(params)
      if code_type == 'expired'
        [current_url, :alert, I18n.t('profiles.notice.expired_promo')]
      elsif code_type == 'extendedtrial'
        [current_url, :alert, I18n.t('profiles.notice.extended_trial_only_for_new_users')]
      else
        [current_url, :alert, I18n.t('profiles.notice.not_valid_promo')]
      end
    elsif (Portal.current_session.logged? || on_login)
      if is_redemption?
        [promo_contact_path, :notice, I18n.t('profiles.notice.promo_validated')]
      else
        # if this promo is valid for the current offer, then use that, else use the opposite offer type
        ot = if valid_for?(params[:offer_type])
               params[:offer_type]
             elsif params[:offer_type] == 'premium'
               'basic'
             else
               'premium'
             end
        [new_order_path({offer_type: ot, order: { billing_option: params[:billing_option], operation: params[:operation] }, operation: params[:operation]}), :notice, I18n.t('profiles.notice.promo_validated')]
      end
    elsif ["termsubscription", "extendedtrial", "discount"].include?(code_type) #nextissue case
      [profile_email_check_path, :notice, I18n.t('profiles.notice.promo_validated')]
    elsif ["consumer", "moveextn"].include?(code_type)  #GCL and shomi case
      [new_session_path, :notice, I18n.t('profiles.notice.promo_validated_sign_in')]
    elsif code_type == "business"   #GCL case
      [promo_business_path, :notice, I18n.t('profiles.notice.promo_validated_register')]
    else
      [root_path, nil, nil]
    end
  end

  def offer
    Offer.find(offer_id: ENV["#{offer_type}_offer_id"]).first
  end

  def price(other_offer = nil)
    return 0.0 if other_offer.nil?

    other_offer.price.to_f - Offer.find(offer_id: ENV['basic_offer_id'], product_code: ENV['APP_NAME']).first.try(:price).to_f
  end

  def is_valid_redemption?
    valid? && is_redemption?
  end

  def is_redemption?
    PromoCode::REDEMPTION_CODE_TYPES.include?(code_type)
  end

  def is_etf?
    code_type == 'extendedtrial'
  end

  def valid_for?(type)
    valid_offers.include?(type.to_s.downcase)
  end

  def basic_redemption?
    valid_for?('basic')
  end

  def premium_redemption?
    valid_for?('premium')
  end

  def desc(lang='en')
    try("desc_#{lang}")
  end

  def first_valid_offer_type(type=nil)
    if valid_for?(type)
      type
    elsif valid_for?('premium')
      'premium'
    elsif valid_for?('basic')
      'basic'
    else
      'current'
    end
  end
end