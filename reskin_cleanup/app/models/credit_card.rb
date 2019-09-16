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
                :field_creditCardHolderName, :field_creditCardState, :field_creditCardAddress1, :field_creditCardCity, :field_creditCardPostalCode, :field_phone, :field_email, :field_creditCardExpirationMonth, :field_creditCardExpirationYear, :field_creditCardCountry,
                :field_passthrough1, :field_passthrough2, :field_passthrough3, :field_passthrough4, :field_passthrough5, :tos, :auto_renew, :masked_cc, :validate, :nhl_opt_in




  validates_format_of :field_creditCardPostalCode, with: /\A([a-zA-Z]\d[a-zA-z]( )?\d[a-zA-Z]\d)\z/
  validates_format_of :field_phone, with: /\A\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z/
  validates_inclusion_of :field_creditCardState, in: Portal::ZUORA_CA_STATES['en'].values + Portal::ZUORA_US_STATES['en'].values, allow_blank: true, if: -> { ['CAN', 'USA'].include?(field_creditCardCountry) }
  validates_presence_of :birthdate, :field_creditCardHolderName, :field_creditCardState, :field_creditCardAddress1, :field_creditCardCity, :field_creditCardPostalCode, :field_phone, :field_email, :field_creditCardExpirationMonth, :field_creditCardExpirationYear, :field_creditCardCountry
  validates_presence_of :field_creditCardNumber, :field_cardSecurityCode, if: -> { validate == 'true'}
  validates_format_of :field_creditCardNumber, with: /\A\d+\z/, if: -> { validate == 'true'}
  validates_format_of :field_cardSecurityCode, with: /\A\d+\z/, if: -> { validate == 'true'}
  validates_length_of :field_creditCardCity, maximum: 20
  validates_acceptance_of :tos


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
          errors.add(field, ERROR_CODES[v])
      end
    end

    # Since we're using JS autodetection lib
    errors.add(:field_creditCardNumber, :invalid) if params[:errorField_creditCardType] == 'NullValue'


    errors.add(:tos, :accepted) unless @tos
  end

end
