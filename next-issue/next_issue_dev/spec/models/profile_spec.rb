require 'spec_helper'

describe Profile do
  let(:profile) { FactoryGirl.build(:profile) }
  let(:new_user_entitlement) { {"entitlement"=>"NEXTISSUE", "level"=>"noRogersAccount", "code"=>"NA"} }

  context '#valid?' do
    it 'valid factory' do
      expect(profile.valid?).to eql true
    end
  end

  it { should validate_presence_of :email_address }
  it { should validate_presence_of :password }
  it { should validate_presence_of :lang_pref }
  it { should validate_presence_of :question }
  it { should validate_presence_of :answer }
  it { should validate_confirmation_of(:email_address).with_message("Email confirmation doesn't match") }

  it do
    should validate_confirmation_of(:password).
             with_message('Your passwords don\'t match')
  end

  it { should allow_value('1').for(:tos) }
  it { should_not allow_value(true).for(:tos) }
  it { should_not allow_value(false).for(:tos) }

  it { should validate_length_of(:answer).is_at_most(40) }
  it { should validate_length_of(:password).is_at_least(7) }
  it { should validate_length_of(:password).is_at_most(16) }

  it { should allow_value('555-555-5555').for(:phone) }
  it { should allow_value('555.555.5555').for(:phone) }
  it { should allow_value('555 555 5555').for(:phone) }
  it { should allow_value('5555555555').for(:phone) }
  it { should_not allow_value('555-555-555').for(:phone) }
  it { should_not allow_value('1-555-555-5555').for(:phone) }

  it { should allow_value('a@t.com').for(:email_address) }
  it { should_not allow_value('invalid').for(:email_address) }

  context "profile state" do
    let(:account) { FactoryGirl.build(:account) }
    before do
      ENV['allow_profile_user_states'] = 'true'
      profile.entitlement = new_user_entitlement
      profile.save
    end

    context "#rogers_user_state" do
      context "profile has a rogers account" do
        before do
          account.save
          profile.accounts << account
        end

        it "returns entitlement without changing rogers account" do
          expect(profile.rogers_user_state).to eql new_user_entitlement
          expect(profile.accounts.size).to eql 1
          expect(profile.accounts.first.account_token).to eql 'somehash42'
        end
      end

      context "profile does not have a rogers account" do
        it "adds 2 test rogers accounts" do
          profile.rogers_user_state
          expect(profile.accounts.size).to eql 2
          expect(profile.accounts.map(&:account_token)).to eql ['CAN:123456|PROVINCE:ON|TYPE:Cable|FIRSTNAME:JON|LASTNAME:DOE', 'BAN:123456|CTN:12345|PROVINCE:ON|TYPE:Rogers Wireless|FIRSTNAME:JON|LASTNAME:DOE']
        end
      end
    end

    context "#basic_redemption_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a basic new user order to the profile" do
          profile.basic_redemption_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'New'
          expect(br.existing_offer_type).to eql 'Basic'
          expect(br.billing_option).to eql 'free'
        end

        it "should return the entitlement code 0, level promo, and promo data of a basic redemption" do
          result = profile.basic_redemption_state
          expect(result['code']).to eql '0'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "TermSubscription"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.basic_redemption_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 0, level promo, and promo data of a basic redemption" do
          result = profile.basic_redemption_state
          expect(result['code']).to eql '0'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "TermSubscription"
        end
      end
    end

    context "#premium_redemption_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a premium new user order to the profile" do
          profile.premium_redemption_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'New'
          expect(br.existing_offer_type).to eql 'Premium'
          expect(br.billing_option).to eql 'free'
        end

        it "should return the entitlement code 1, level promo, and promo data of a basic redemption" do
          result = profile.premium_redemption_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "TermSubscription"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.premium_redemption_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 1, level promo, and promo data of a basic redemption" do
          result = profile.premium_redemption_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "TermSubscription"
        end
      end
    end

    context "#topup_redemption_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a new basic, and premium topup user orders to the profile" do
          profile.topup_redemption_state
          expect(profile.user_orders.size).to eql 2
          expect(profile.user_orders.map(&:status)).to eql ['TopUp', 'New']
          expect(profile.user_orders.map(&:existing_offer_type)).to eql ['Premium', 'Basic']
          expect(profile.user_orders.map(&:billing_option)).to eql ['cc', 'cc']
        end

        it "should return the entitlement code 1, level promotopup, and promo data of a basic redemption" do
          result = profile.topup_redemption_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promotopup'
          expect(result[:promo_data]['promo_type']).to eql "TermSubscription"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.topup_redemption_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 1, level promotopup, and promo data of a basic redemption" do
          result = profile.topup_redemption_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promotopup'
          expect(result[:promo_data]['promo_type']).to eql "TermSubscription"
        end
      end
    end

    context "#basic_etf_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a basic new user order to the profile" do
          profile.basic_etf_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'New'
          expect(br.existing_offer_type).to eql 'Basic'
          expect(br.billing_option).to eql 'cc'
        end

        it "should return the entitlement code 0, level promo, and promo data of an extended free trial" do
          result = profile.basic_etf_state
          expect(result['code']).to eql '0'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "ExtendedTrial"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.basic_etf_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 0, level promo, and promo data of an extended free trial" do
          result = profile.basic_etf_state
          expect(result['code']).to eql '0'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "ExtendedTrial"
        end
      end
    end

    context "#premium_etf_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a premium new user order to the profile" do
          profile.premium_etf_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'New'
          expect(br.existing_offer_type).to eql 'Premium'
          expect(br.billing_option).to eql 'cc'
        end

        it "should return the entitlement code 1, level promo, and promo data of an extended free trial" do
          result = profile.premium_etf_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "ExtendedTrial"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.premium_etf_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 1, level promo, and promo data of an extended free trial" do
          result = profile.premium_etf_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "ExtendedTrial"
        end
      end
    end

    context "#basic_discount_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a basic new user order to the profile" do
          profile.basic_discount_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'New'
          expect(br.existing_offer_type).to eql 'Basic'
          expect(br.billing_option).to eql 'cc'
        end

        it "should return the entitlement code 0, level promo, and promo data of an extended free trial" do
          result = profile.basic_discount_state
          expect(result['code']).to eql '0'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "Discount"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.basic_discount_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 0, level promo, and promo data of an extended free trial" do
          result = profile.basic_discount_state
          expect(result['code']).to eql '0'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "Discount"
        end
      end
    end

    context "#premium_discount_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a premium new user order to the profile" do
          profile.premium_discount_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'New'
          expect(br.existing_offer_type).to eql 'Premium'
          expect(br.billing_option).to eql 'cc'
        end

        it "should return the entitlement code 1, level promo, and promo data of an extended free trial" do
          result = profile.premium_discount_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "Discount"
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.premium_discount_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code 1, level promo, and promo data of an extended free trial" do
          result = profile.premium_discount_state
          expect(result['code']).to eql '1'
          expect(result['level']).to eql 'promo'
          expect(result[:promo_data]['promo_type']).to eql "Discount"
        end
      end
    end

    context "#cancelled_state" do
      context "ENV['user_orders'] is true" do
        before { ENV['user_orders'] = 'true' }
        it "should add a cancelled basic user order to the profile" do
          profile.cancelled_state
          expect(profile.user_orders.size).to eql 1
          br = profile.user_orders.first
          expect(br.status).to eql 'Cancelled'
          expect(br.existing_offer_type).to eql 'Basic'
          expect(br.billing_option).to eql 'cc'
        end

        it "should return the entitlement code na, and ineligible level" do
          result = profile.cancelled_state
          expect(result['code']).to eql 'NA'
          expect(result['level']).to eql 'ineligible'
        end
      end

      context "ENV['user_orders'] is nil" do
        before { ENV['user_orders'] = nil }
        it "should not add anything to the profile user orders" do
          profile.cancelled_state
          expect(profile.user_orders.size).to eql 0
        end

        it "should return the entitlement code na, and ineligible level" do
          result = profile.cancelled_state
          expect(result['code']).to eql 'NA'
          expect(result['level']).to eql 'ineligible'
        end
      end
    end
  end
end