class Offer < Portal
  attribute :offer_id # Rogers offer id
  attribute :price
  attribute :frequency
  attribute :desc_en
  attribute :desc_fr
  attribute :product_code
  attribute :reward_points
  attribute :reward_point_desc_en
  attribute :reward_point_desc_fr

  index :offer_id
  index :product_code

  def can_upgrade?
    offer_id == ENV['basic_offer_id']
  end

  def basic?
    offer_id == ENV['basic_offer_id']
  end

  def premium?
    offer_id == ENV['premium_offer_id']
  end

  def topup?
    offer_id == ENV['topup_offer_id']
  end

  def price_dollars
    price ? price.split(/\./).first : nil
  end

  def price_cents
    price ? price.split(/\./).last : nil
  end

  def description(lang = 'en')
    send("desc_#{lang}")
  end

  def reward_description(lang = 'en')
    send("reward_point_desc_#{lang}")
  end

  def full_reward_description(lang = 'en')
    "#{reward_points} #{reward_description(lang)}"
  end

  def loyalty_suffix
    suffix = ""
    if ENV["APP_NAME"] == "nextissue"
      if offer_id == ENV["basic_offer_id"]
        suffix = "b"
      elsif offer_id == ENV["premium_offer_id"]
        suffix = "p"
      else
        suffix = "b"
      end
    else
      suffix = ""
    end
    return suffix
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

  def self.top_up_cost
    top_up = Offer.find(offer_id: 'topupcost').first
    if top_up.nil?
      b = Offer.find(offer_id: ENV['basic_offer_id'], product_code: ENV['APP_NAME']).first
      p = Offer.find(offer_id: ENV['premium_offer_id'], product_code: ENV['APP_NAME']).first
      top_up = Offer.new(offer_id: 'topupcost', product_code: b.product_code, price: p.price.to_f - b.price.to_f)
      top_up.save
    end
    top_up.price.to_f
  end
end