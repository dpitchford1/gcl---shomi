class Offer < Portal
  attribute :offer_id # Rogers offer id
  attribute :price
  attribute :frequency
  attribute :desc_en
  attribute :desc_fr
  attribute :product_code

  index :offer_id
  index :product_code


  def price_dollars
    price ? price.split(/\./).first : nil
  end

  def price_cents
    price ? price.split(/\./).last : nil
  end

  def description(lang = 'en')
    send("desc_#{lang}")
  end

  def self.current_offer(params = {})
    if params[:offer_id]
      cur_offer_id  = params[:offer_id]
    else
      cur_offer_id = params[:user_region] ? ENV['current_rds_games_offer_id'] : ENV['current_offer_id']
    end    
    offer = Offer.find(offer_id: cur_offer_id).first
    offer ||= Offer.find(product_code: ENV['APP_NAME'].downcase).first
    offer
  end

end