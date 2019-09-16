class UserOrder < Portal
  attribute :order_date
  attribute :activation_date
  attribute :order_id
  attribute :offer_id
  attribute :billing_option
  attribute :billing_account # Rogers account, masked credit card no or promo code
	attribute :billing_amount
  attribute :taxes
  attribute :billing_frequency
  attribute :desc_en
  attribute :desc_fr
  attribute :status
  attribute :existing_offer_type

  attribute :masked_cc
  attribute :full_name
  attribute :street
  attribute :address2
  attribute :city
  attribute :province
  attribute :postal_code

  attribute :membership_number
  attribute :loyalty_partner

  index :order_id
  index :offer_id

  delegate :can_upgrade?, :description, :price, to: :offer, allow_nil: true, prefix: true

  def offer
    Offer.find(offer_id: offer_id).first || Offer.find(offer_id:  ENV["#{existing_offer_type.to_s.downcase}_offer_id"]).first
  end

  def description(lang = 'en')
    try("desc_#{lang}")
  end

  def short_description
    existing_offer_type ? I18n.t("offers.description.#{existing_offer_type.downcase}") : ''
  end

  def short_description_backwards
    existing_offer_type ? I18n.t("offers.description.backwards.#{existing_offer_type.downcase}") : ''
  end

  def total
    (taxes.to_f + billing_amount.to_f).round(2)
  end

  def order_attributes(params={})
    billing_option = params[:billing_option] || billing_option
    operation = params[:operation] || operation
    edit_order_id = status.to_s.downcase == 'cancelled' ? nil : order_id
    credit_card_province = Portal::ZUORA_CA_STATES['en'][province.to_s] || Portal::ZUORA_CA_STATES['fr'][province.to_s]
    if billing_option == 'cc'
      { offer_type: existing_offer_type.to_s.downcase, order: { billing_option: billing_option, order_id: edit_order_id, offer_id: offer_id }, operation: operation, field_creditCardHolderName: full_name, field_creditCardState: credit_card_province, field_creditCardAddress1: street, field_creditCardAddress2: address2, field_creditCardCity: city, field_creditCardPostalCode: postal_code, membership_number: membership_number }
    elsif billing_option == 'rogersbill'
      { offer_type: existing_offer_type.to_s.downcase, order: { billing_option: billing_option, order_id: edit_order_id, offer_id: offer_id, operation: operation, rogers_account_token: billing_account, membership_number: membership_number } }
    else
      { offer_type: existing_offer_type.to_s.downcase, order: { billing_option: 'cc', order_id: edit_order_id, offer_id: offer_id }, operation: operation, field_creditCardHolderName: full_name, field_creditCardState: credit_card_province, field_creditCardAddress1: street, field_creditCardAddress2: address2, field_creditCardCity: city, field_creditCardPostalCode: postal_code, membership_number: membership_number }
    end
  end

  def credit_attributes(params={})
    operation = params[:operation] || operation
    credit_card_province = Portal::ZUORA_CA_STATES['en'][province.to_s] || Portal::ZUORA_CA_STATES['fr'][province.to_s]

    { operation: operation, field_creditCardHolderName: full_name, field_creditCardState: credit_card_province, field_creditCardAddress1: street, field_creditCardAddress2: address2, field_creditCardCity: city, field_creditCardPostalCode: postal_code, membership_number: membership_number }
  end

  def basic?
    existing_offer_type.to_s.downcase == 'basic'
  end

  def premium?
    existing_offer_type.to_s.downcase == 'premium'
  end

  # Same day as the order's activation_date
  def next_billing_cycle_date
    ad = Date.parse(activation_date) rescue nil

    unless ad.nil?
      next_billing_cycle = Date.parse(Time.now.gmtime.to_s)
      # if today is after the order date, then next billing cycle is next month
      if ad.day < next_billing_cycle.day
        next_billing_cycle = next_billing_cycle + 1.months
      end

      next_billing_cycle = next_billing_cycle + (ad.day - next_billing_cycle.day).days

      if next_billing_cycle.day < ad.day
        return next_billing_cycle - next_billing_cycle.day.days
      else
        return next_billing_cycle
      end
    end
  end
end

