require 'spec_helper'

describe Order do
  let(:offer) { FactoryGirl.build(:offer) }
  let(:order) { FactoryGirl.build(:order) }
  let(:order_w_dob) { Order.new(:"birthdate(1i)"=>"1927", :"birthdate(2i)"=>"3", :"birthdate(3i)"=>"15") }
  let(:account) { FactoryGirl.build(:account) }
  let(:profile) { FactoryGirl.build(:profile) }
  let(:session) { FactoryGirl.build(:session) }

  context '#province!' do
    context 'with rogers account token' do
      before { order.rogers_account_token = 'somehash42' }

      it 'sets the province to the account\'s billing province' do
        expect(Account).to receive(:find).with(account_token: 'somehash42').and_return([account])
        order.province!
        expect(order.province).to eql 'Ontario'
      end

      it 'does not change the order when there is no associated rogers account' do
        expect(Account).to receive(:find).with(account_token: 'somehash42').and_return([])
        order.province!
        expect(order.province).to be_nil
      end
    end
  end

  context '#offer' do
    it 'return nil when there are no results from the offer id or the product code' do
      expect(Offer).to receive(:find).with(offer_id: 42).and_return([])
      expect(order.offer).to be_nil
    end

    it 'return current_offer from offer id given' do
      expect(Offer).to receive(:find).with(offer_id: 42).and_return([offer])
      o = order.offer
      expect(o).to_not be_nil
      expect(o.attributes).to eql offer.attributes
    end
  end

  context '#taxes' do
    it 'return ( price * (pst + gst)/100 ).round(2)' do
      order.province ='ON'
      order.price = 100.50
      expect(order.taxes).to eql 13.07
    end

    it 'return nil when province does not match one from pst' do
      order.province ='Ontario'
      expect(order.taxes).to be_nil
    end

    it 'return nil without province' do
      expect(order.taxes).to be_nil
    end
  end

  context '#total' do
    it 'return ( taxes + price )' do
      expect(order).to receive(:taxes).and_return(12.25)
      order.price = '12.94'
      expect(order.total).to eql 25.19
    end

    it 'return 0 when taxes & price add up to 0' do
      expect(order).to receive(:taxes).and_return(0)
      order.price = '0'
      expect(order.total).to eql 0.0
    end
  end

  context '#remote_save' do
    it 'return true when remote api calls are stubbed & ohm redis saving are stubbed' do
      # stub saving by manually setting the order id
      order.send('id=', 5000)
      expect(order).to receive(:save).and_return(true)

      # mock the 'unreliable' get_entitlements call
      fake_ip_addr = '123.456.789.101'
      mock_client = double('api_client')
      expect(mock_client).to receive(:create_order).and_return({ order_id: 5000 })
      # use a mock to avoid calling the godzilla api to create the order remotely
      expect(order).to receive(:api_client).and_return(mock_client).exactly(1).times

      mock_order = double('Order')
      expect(mock_order).to receive(:delete).and_return(true)
      # use a mock to avoid delay deleting the order
      expect(Order).to receive(:delay_for).and_return(mock_order)

      expect(order.remote_save(fake_ip_addr)).to eql true
    end
  end

  it { should validate_presence_of :offer_id }
  it { should validate_presence_of :birthdate }

  it { should allow_value('1').for(:tos) }
  it { should_not allow_value(true).for(:tos) }
  it { should_not allow_value(false).for(:tos) }

  context 'free billing option' do
    before { order.billing_option = 'free' }
    it { expect(order).to validate_presence_of :first_name }
    it { expect(order).to validate_presence_of :last_name }
    it { expect(order).to validate_presence_of :street }
    it { expect(order).to validate_presence_of :city }
    it { expect(order).to validate_presence_of :province }
    it { expect(order).to validate_presence_of :postal_code }
  end

  context 'rogersbill billing option' do
    before { order.billing_option = 'rogersbill' }

    it { expect(order).to validate_presence_of :rogers_account_token }
    it { expect(order).to validate_presence_of :phone_number }
  end

  context 'cc billing option' do
    before { order.billing_option = 'cc' }

    it { expect(order).to validate_presence_of :offer_id }
    it { expect(order).to validate_presence_of :birthdate }
    it { expect(order).to validate_presence_of(:postal_code).with_message('is invalid') }
  end

  it 'should not have a dob error when it is passed in as parameters' do
    order_w_dob.valid?
    expect(order_w_dob.errors.messages.has_key?(:birthdate)).to eql false
  end

  context 'skip birthday validation!' do
    before { order.skip_birthdate_validation! }

    it { expect(order).to_not validate_presence_of :birthdate }
  end

  context 'skip phone_number validation!' do
    before { order.skip_phone_number_validation! }

    it { expect(order).to_not validate_presence_of :phone_number }
  end

  context 'has offer' do
    before { expect(Offer).to receive(:find).with(offer_id: 42).and_return([offer]) }
    context '#description' do
      it 'should return offer description' do
        expect(order.description).to eql offer.description
      end
    end

    context '#can_upgrade?' do
      it 'should return whether offer can upgrade' do
        expect(offer).to receive(:can_upgrade?).and_return(true)
        expect(order.can_upgrade?).to eql true
      end
    end

    context '#offer_price' do
      it 'should return offer price' do
        order.price = '4.54'
        expect(order.offer_price).to eql offer.price
      end
    end
  end

  context 'nil offer' do
    before { expect(Offer).to receive(:find).with(offer_id: 42).and_return([]) }
    context '#description' do
      it 'should return offer description' do
        expect(order.description).to be_nil
      end
    end

    context '#can_upgrade?' do
      it 'should return whether offer can upgrade' do
        expect(offer).to_not receive(:can_upgrade?)
        expect(order.can_upgrade?).to be_nil
      end
    end

    context '#offer_price' do
      it 'should return offer price' do
        order.price = '4.54'
        expect(order.offer_price).to be_nil
      end
    end
  end
end
