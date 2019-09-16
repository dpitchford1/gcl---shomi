require 'spec_helper'

describe Offer do
  let(:offer) { FactoryGirl.build(:offer) }

  context '#price_dollars' do
    it 'show the dollar amount' do
      expect(offer.price_dollars).to eql '1'
    end
    it 'return nil if there is no price' do
      expect(Offer.new.price_dollars).to eql nil
    end
  end

  context '#price_cents' do
    it 'show the cent amount' do
      expect(offer.price_cents).to eql '25'
    end
    it 'return nil if there is no price' do
      expect(Offer.new.price_cents).to eql nil
    end
  end

  context '#description' do
    it 'return english description by default' do
      expect(offer.description).to eql 'test offer'
    end
    it 'return fr description' do
      expect(offer.description('fr')).to eql 'fr test offer'
    end
  end

  context '.current_offer' do
    it 'return nil when there are no results from the offer id or the product code' do
      expect(Offer).to receive(:find).with(offer_id: 42).and_return([])
      expect(Offer).to receive(:find).with(product_code: 'nextissue').and_return([])
      expect(Offer.current_offer({ offer_id: 42 })).to be_nil
    end

    it 'return current_offer from offer id given' do
      expect(Offer).to receive(:find).with(offer_id: 42).and_return([offer])
      expect(Offer).to_not receive(:find).with(product_code: 'nextissue')
      o = Offer.current_offer({ offer_id: 42 })
      expect(o).to_not be_nil
      expect(o.attributes).to eql offer.attributes
    end

    it 'return current_offer from the ENV[\'APP_NAME\'] product code' do
      expect(Offer).to receive(:find).with(offer_id: 42).and_return([])
      expect(Offer).to receive(:find).with(product_code: 'nextissue').and_return([offer])
      o = Offer.current_offer({ offer_id: 42 })
      expect(o).to_not be_nil
      expect(o.attributes).to eql offer.attributes
    end
  end

  context '#basic?' do
    it 'return false when offer id is the neither premium or basic' do
      offer.offer_id = 42
      expect(offer.basic?).to eql false
    end

    it 'return true when offer id is the basic offer id' do
      expect(offer.basic?).to eql true
    end

    it 'return false when offer id is the premium offer id' do
      offer.offer_id = ENV['premium_offer_id']
      expect(offer.basic?).to eql false
    end
  end

  context '#premium?' do
    it 'return false when offer id is the neither premium or basic' do
      offer.offer_id = 42
      expect(offer.premium?).to eql false
    end

    it 'return true when offer id is the premium offer id' do
      offer.offer_id = ENV['premium_offer_id']
      expect(offer.premium?).to eql true
    end

    it 'return false when offer id is the basic offer id' do
      expect(offer.premium?).to eql false
    end
  end
end
