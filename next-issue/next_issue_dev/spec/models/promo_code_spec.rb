require 'spec_helper'

describe PromoCode do
  [:promo_code, :discount_code, :redemption_code, :invalid_code, :expired_code, :consumer_code, :business_code, :free_trial_code].each { |code_type| let(code_type) { FactoryGirl.build(code_type) } }

  context '.check' do
  end

  context '#valid?' do
    it 'return false if invalid' do
      expect(invalid_code.valid?).to eql false
    end

    it 'return false if expired' do
      expect(expired_code.valid?).to eql false
    end

    it 'return true if valid for product matches app name' do
      expect(promo_code.valid?).to eql true
    end
  end

  context '#redirect' do
    context 'unregistered user' do
      let(:current_session) { FactoryGirl.build(:unregistered_session) }
      before do
        # Since applicaiton controller's 'current_session' always sets the Portal.current_session we can assume that Portal.current_session will never be nil
        allow(current_session).to receive(:logged?).and_return(false)
        allow(Portal).to receive(:current_session).and_return(current_session)
      end

      context 'on login' do
        context 'offer type is basic' do
          let(:redirect_params) { {offer_type: 'basic'} }
          # Validation failing should prevent this case on login
          it 'returns basic new order path with promo code validated notice when code has expired & offer type is basic' do
            allow(expired_code).to receive(:valid?).and_return(false)
            expect(expired_code.redirect(redirect_params, true)).to eql ['/orders/new?offer_type=basic&order%5Bbilling_option%5D=&order%5Boperation%5D=', :notice, 'Promo code validated.']
          end

          it 'returns new order path with promo code validated notice' do
            allow(promo_code).to receive(:valid?).and_return(true)
            expect(promo_code.redirect(redirect_params, true)).to eql ['/orders/new?offer_type=basic&order%5Bbilling_option%5D=&order%5Boperation%5D=', :notice, 'Promo code validated.']
          end

          it 'returns new order path with billing option set' do
            allow(promo_code).to receive(:valid?).and_return(true)
            expect(promo_code.redirect({billing_option: 'rogersbill'}, true)).to eql ['/orders/new?offer_type=premium&order%5Bbilling_option%5D=rogersbill&order%5Boperation%5D=', :notice, 'Promo code validated.']
          end
        end
      end

      context 'not on login' do
        context 'validate redemption only' do
          it 'returns current path when invalid code' do
            invalid_code.current_url = '/somewhere'
            expect(invalid_code).to receive(:valid?).and_return(false)
            expect(invalid_code.redirect({validate_redemption_only: 'true'})).to eql ['/somewhere', :alert, 'Oops! This is an invalid coupon code.']
          end

          it 'returns current path when expired code' do
            expired_code.current_url = '/somewhere'
            expect(expired_code).to receive(:valid?).and_return(false)
            expect(expired_code.redirect({validate_redemption_only: 'true'})).to eql ['/somewhere', :alert, 'The Redemption code expired']
          end

          it 'returns current path and invalid promo code alert when valid test promo code type' do
            promo_code.current_url = '/somewhere'
            expect(promo_code).to receive(:valid?).and_return(true)
            expect(promo_code.redirect({validate_redemption_only: 'true'})).to eql ['/somewhere', :alert, 'Oops! This is an invalid coupon code.']
          end

          it 'returns current path and invalid promo code alert when valid redemption' do
            expect(redemption_code).to receive(:valid?).and_return(true)
            expect(redemption_code.redirect({validate_redemption_only: 'true'})).to eql ['/email_check', :notice, 'Promo code validated.']
          end
        end

        context 'not validating redemption only' do
          it 'returns current path when invalid code' do
            invalid_code.current_url = '/somewhere'
            expect(invalid_code).to receive(:valid?).and_return(false)
            expect(invalid_code.redirect).to eql ['/somewhere', :alert, 'Oops! This is an invalid coupon code.']
          end

          it 'returns current path when valid redemption' do
            redemption_code.current_url = '/somewhere'
            expect(redemption_code).to receive(:valid?).and_return(true)
            expect(redemption_code.redirect).to eql ['/somewhere', :alert, 'Oops! This is an invalid coupon code.']
          end

          it 'returns current path when expired code' do
            expired_code.current_url = '/somewhere'
            expect(expired_code).to receive(:valid?).and_return(false)
            expect(expired_code.redirect).to eql ['/somewhere', :alert, 'The Redemption code expired']
          end

          it 'returns root path when valid test promo code type' do
            expect(promo_code).to receive(:valid?).and_return(true)
            expect(promo_code.redirect).to eql ['/', nil, nil]
          end

          it 'returns email check path with valid discount' do
            expect(discount_code).to receive(:valid?).and_return(true)
            expect(discount_code.redirect).to eql ['/email_check', :notice, 'Promo code validated.']
          end

          # moveextn code type results in same path
          it 'returns sign in path with valid consumer code' do
            expect(consumer_code).to receive(:valid?).and_return(true)
            expect(consumer_code.redirect).to eql ['/signin', :notice, 'Promo code validated. Please sign in.']
          end

          it 'returns promo business path with valid business code' do
            expect(business_code).to receive(:valid?).and_return(true)
            expect(business_code.redirect).to eql ['/profiles/promo_business', :notice, 'Promo code validated. Please register.']
          end
        end
      end
    end
  end

  context '#price' do
    context 'other offer is premium' do
      let(:other_offer) { FactoryGirl.build(:offer, price: '14.99') }
      let(:offer) { FactoryGirl.build(:offer) }

      it 'return difference in prices' do
        expect(Offer).to receive(:find).with(offer_id: ENV['basic_offer_id'], product_code: ENV['APP_NAME']).and_return([offer])
        expect(promo_code.price(other_offer)).to eql 13.74
      end

      it 'return difference in prices' do
        expect(Offer).to receive(:find).with(offer_id: ENV['basic_offer_id'], product_code: ENV['APP_NAME']).and_return([offer])
        expect(promo_code.price(offer)).to eql 0.0
      end
    end

    context 'offer is nil' do
      it 'return 0.0' do
        expect(promo_code.price(nil)).to eql 0.0
      end
    end

    context 'other_offer is nil' do
      it 'return 0.0' do
        expect(promo_code.price(nil)).to eql 0.0
      end
    end
  end

  context '#is_valid_redemption?' do
    it 'returns true when both valid & redemption' do
      expect(promo_code).to receive(:valid?).and_return(true).exactly(1).times
      expect(promo_code).to receive(:is_redemption?).and_return(true).exactly(1).times
      expect(promo_code.is_valid_redemption?).to eql true
    end
    it 'returns false when not valid' do
      expect(promo_code).to receive(:valid?).and_return(false).exactly(1).times
      expect(promo_code).to receive(:is_redemption?).and_return(true).exactly(0).times
      expect(promo_code.is_valid_redemption?).to eql false
    end
    it 'returns false when not redemption' do
      expect(promo_code).to receive(:valid?).and_return(true).exactly(1).times
      expect(promo_code).to receive(:is_redemption?).and_return(false).exactly(1).times
      expect(promo_code.is_valid_redemption?).to eql false
    end
  end

  context '#is_redemption?' do
    it 'returns true when termedsubscription' do
      expect(redemption_code.is_redemption?).to eql true
    end
    it 'returns false when discount' do
      expect(discount_code.is_redemption?).to eql false
    end
  end

  context '#valid_for_params?' do
    let(:params) { {} }
    context 'no params' do
      it 'return false if valid redemption' do
        expect(redemption_code).to receive(:valid?).and_return(true)
        expect(redemption_code.valid_for_params?).to eql false
      end

      it 'return true if valid discount' do
        expect(discount_code).to receive(:valid?).and_return(true)
        expect(discount_code.valid_for_params?).to eql true
      end

      it 'return true if valid business_code' do
        expect(business_code).to receive(:valid?).and_return(true)
        expect(business_code.valid_for_params?).to eql true
      end
    end

    context 'validate redemption only is true' do
      before { params[:validate_redemption_only] = 'true' }

      it 'return true if valid redemption' do
        expect(redemption_code).to receive(:valid?).and_return(true)
        expect(redemption_code.valid_for_params?(params)).to eql true
      end

      it 'return false if invalid redemption' do
        expect(redemption_code).to receive(:valid?).and_return(false)
        expect(redemption_code.valid_for_params?(params)).to eql false
      end

      it 'return false if valid discount' do
        expect(discount_code).to receive(:valid?).and_return(true)
        expect(discount_code.valid_for_params?(params)).to eql false
      end
    end

    context 'validate redemption only is false' do
      before { params[:validate_redemption_only] = 'false' }

      context 'eligible user' do
        before { params[:user_is_active] = true }

        it 'return false if valid etf' do
          expect(free_trial_code).to receive(:valid?).and_return(true)
          expect(free_trial_code.valid_for_params?(params)).to eql false
        end

        it 'return false if invalid etf' do
          expect(free_trial_code).to receive(:valid?).and_return(false)
          expect(free_trial_code.valid_for_params?(params)).to eql false
        end

        it 'return true if valid discount' do
          expect(discount_code).to receive(:valid?).and_return(true)
          expect(discount_code.valid_for_params?(params)).to eql true
        end
      end

      context 'ineligible user' do
        before { params[:user_is_active] = nil }

        it 'return true if valid etf' do
          expect(free_trial_code).to receive(:valid?).and_return(true)
          expect(free_trial_code.valid_for_params?(params)).to eql true
        end

        it 'return false if invalid etf' do
          expect(free_trial_code).to receive(:valid?).and_return(false)
          expect(free_trial_code.valid_for_params?(params)).to eql false
        end

        it 'return true if valid discount' do
          expect(discount_code).to receive(:valid?).and_return(true)
          expect(discount_code.valid_for_params?(params)).to eql true
        end
      end
    end
  end
end