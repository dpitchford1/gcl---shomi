class CreditCard
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  include ActiveModel::AttributeMethods

  attr_accessor :id, :tenantId, :timestamp, :token, :signature, :field_accountId, :field_gatewayName, :field_deviceSessionId, :field_ipAddress, 
                :field_useDefaultRetryRule, :field_paymentRetryWindow, :field_maxConsecutivePaymentFailures, :field_creditCardType, :field_creditCardNumber, :field_cardSecurityCode, 
                :field_creditCardHolderName, :field_creditCardState, :field_creditCardAddress1, :field_creditCardAddress2, :field_creditCardCity, :field_creditCardPostalCode, :field_phone, :field_email, :field_creditCardExpirationMonth, :field_creditCardExpirationYear, :field_creditCardCountry,
                :field_passthrough1, :field_passthrough2, :field_passthrough3, :field_passthrough4, :field_passthrough5, :tos, :auto_renew, :masked_cc, :validate, :nhl_opt_in,
                :loyalty_code, :membership_number, :membership_type, :promo_code, :code_type, :desc, :validation_type, :operation, :offer_type


  validates_format_of :field_creditCardPostalCode, with: /\A([a-zA-Z]\d[a-zA-z]( )?\d[a-zA-Z]\d)\z/, allow_blank: true
  validates_format_of :field_phone, with: /\A\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z/,  :if => -> { !skip_field_phone_validation? }
  validates_inclusion_of :field_creditCardState, in: Portal::ZUORA_CA_STATES['en'].values + Portal::ZUORA_US_STATES['en'].values, allow_blank: true, if: -> { ['CAN', 'USA'].include?(field_creditCardCountry) }
  validates_presence_of :birthdate,  :if => -> { !skip_birthdate_validation? }
  validates_presence_of :field_phone,  :if => -> { !skip_field_phone_validation? }
  validates_presence_of :field_email,  :if => -> { !skip_field_email_validation? }
  validates_presence_of :field_creditCardHolderName, :field_creditCardState, :field_creditCardAddress1, :field_creditCardCity, :field_creditCardPostalCode, :field_creditCardExpirationMonth, :field_creditCardExpirationYear, :field_creditCardCountry
  validates_presence_of :field_creditCardNumber, :field_cardSecurityCode, if: -> { validate == 'true'}
  validates_format_of :field_creditCardNumber, with: /\A\d+\z/, if: -> { validate == 'true'}, allow_blank: true
  validates_length_of :field_creditCardNumber, maximum: 16, minimum: 13, if: -> { validate == 'true'}
  validates_format_of :field_cardSecurityCode, with: /\A\d+\z/, if: -> { validate == 'true'}
  validates_length_of :field_cardSecurityCode, minimum: 3, if: -> { validate == 'true'}
  validates_length_of :field_creditCardHolderName, maximum: ENV.fetch('credit_card_name_limit', 50).to_i
  validates_length_of :field_creditCardCity, maximum: ENV.fetch('credit_card_city_limit', 30).to_i
  validates_acceptance_of :tos
  validate :membership_number_is_valid_length
  validate :correct_creditcard_used

  def correct_creditcard_used
    if validation_type
      # amex       - First digit must be a 3 and second digit must be a 4 or 7. Valid length: 15 digits.
      # mastercard - First digit must be a 5 and second digit must be in the range 1 through 5 inclusive. Valid length: 16 digits.
      # visa       - First digit must be a 4. Valid length: 13 or 16 digits.
      if (validation_type == 'amex' && !field_creditCardNumber.match(/\A3[4|7]\d{13}\z/)) ||
          (validation_type == 'mastercard' && !field_creditCardNumber.match(/\A5[1-5]\d{14}\z/)) ||
          (validation_type == 'visa' && !field_creditCardNumber.match(/\A4\d{12,15}\z/))

        errors.add(:field_creditCardNumber, I18n.t('errors.attributes.field_creditCardNumber.invalid'))
      end
    end
  end

  def get_membership_length
    if membership_type == 'Air Miles'
      11
    elsif membership_type == 'Scene'
      16
    elsif membership_type == 'VIA Préférence'
      7
    end
  end

  #number characters only of certain length based off membership type
  def membership_number_is_valid_length
    if !membership_number.to_s.match(/\A\d+\z/) || membership_number.length < 7 || (get_membership_length && membership_number.length != get_membership_length)
      if !membership_number.blank? && membership_number.downcase != 'none'
        errors.add(:membership_number, I18n.t('errors.attributes.membership_number.too_short'))
      end
    end
  end

  # call order.skip_birthdate_validation! to avoid requiring birthdate
  %w(birthdate field_phone field_email).each do |field|
    define_method "skip_#{field}_validation?" do
      self.instance_variable_get("@skip_#{field}_validation") || false
    end

    define_method "skip_#{field}_validation!" do
      self.instance_variable_set("@skip_#{field}_validation", true)
    end
  end

  ERROR_CODES = {
    'NullValue'  => :blank,
    'ExceededMaxLength' => :too_long
  }


  def birthdate
    @birthdate
  end

  def birthdate=(date)
    begin
      case date.class.to_s
      when 'Date'
        @birthdate = date
      when 'String'
        @birthdate = ::Date.parse(date)
      when 'Array'
        @birthdate = ::Date.parse(date.join('-'))
      end
    rescue => ex
      @birthdate = nil
    end
  end

  def process_errors(params)
    valid? # to run validation rules

    cvv_overwrite_error = "Error processing transaction.CVV Note:CVV No Match"
    if params[:errorCode] =~ /CVV/i
      errors.add(:base, :invalid_cvv)
    elsif params[:errorCode] =~ /AVS/i
      errors.add(:base, :invalid_avs)
    elsif params[:errorCode] == 'GatewayTransactionError'
      errors.add(:base, :invalid_cc)
    elsif params[:errorMessage] == cvv_overwrite_error && params[:errorMessage] != 'null'
      errors.add(:base, I18n.t('errors.messages.cvv_no_match'))
    elsif params[:errorMessage] && params[:errorMessage] != 'null'
      errors.add(:base, params[:errorMessage])
    end

    params.each do |k,v|
      if k =~ /^errorField_/
        field = k.gsub('errorField_', 'field_')
        # Don't add the error if the field has been marked to be skipped
        errors.add(field, ERROR_CODES[v]) unless self.try("skip_#{field}_validation?")
      end
    end

    # Since we're using JS autodetection lib
    errors.add(:field_creditCardNumber, :invalid) if params[:errorField_creditCardType] == 'NullValue'


    errors.add(:tos, :accepted) unless @tos
  end

end
