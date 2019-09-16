class PromoCode < Portal
  attribute :code
  attribute :code_type
  attribute :valid_for_product

  index :code
  
  def self.check(params)

    code = params[:code]
    lang = params[:lang]
    I18n.locale = lang

    promo_code = PromoCode.find(code: code).first
    unless promo_code
      promo_code = PromoCode.new(params)
      begin
        result = promo_code.api_client.promo_code?(code)
        promo_code.code_type = result[:code_type].to_s
        promo_code.valid_for_product = result[:valid_for_product].to_s
      rescue GodzillaApi::Exception => e
        promo_code.code_type = 'invalid'
        promo_code.valid_for_product = 'none'
        promo_code.errors.add(:base, e.error["msg_en"])
      end
      promo_code.save
    else
      promo_code.current_url = params[:current_url]
    end
    promo_code.background_params[:promo_code] = promo_code.valid? ? promo_code : nil
    promo_code.background_params[:redirect], promo_code.background_params[:notice_type], promo_code.background_params[:notice] =  *promo_code.redirect
    promo_code
  end

  def valid?
    code_type_check = code_type =~ /^(invalid|used)$/ ? false : true
    valid_for_product_check = valid_for_product.to_s.downcase == ENV["APP_NAME"]
    return code_type_check && valid_for_product_check
    super
  end

  def redirect
    if !valid?
      [current_url, :alert, I18n.t('profiles.notice.not_valid_promo')]
    elsif Portal.current_session.logged?
      [promo_contact_path, :notice, I18n.t('profiles.notice.promo_validated')]
    elsif ["consumer", "moveextn"].include?(code_type)
      [new_session_path, :notice, I18n.t('profiles.notice.promo_validated_sign_in')]
    elsif code_type == "business"
      [promo_business_path, :notice, I18n.t('profiles.notice.promo_validated_register')]
    else
      [root_path, nil, nil]
    end
  end
end