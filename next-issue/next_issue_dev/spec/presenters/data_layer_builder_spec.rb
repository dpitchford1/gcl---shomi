require 'spec_helper'

describe DataLayerBuilder do
  let(:lang) { 'en' }
  let(:flash) { {} }
  let(:session) { {} }
  let(:ineligible_profile) { double('profile', eligible?: false) }

  context 'no parameters' do
    it "should not create any layers" do
      dlb = DataLayerBuilder.new
      expect(dlb.layers.length).to eql 0
    end
  end

  context 'setup_new_user_funnel_layers' do
    context 'unregistered' do
      context '/register' do
        let(:current_path) { '/register' }

        it 'should add a create account event' do
          params = { current_path: current_path, language: lang, session: session, current_session: nil }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en new user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '1 create account'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
        end
      end
    end

    context 'ineligible logged on' do
      let(:current_session) { FactoryGirl.build(:session) }

      before do
        allow(current_session).to receive(:profile).and_return(ineligible_profile)
        expect(current_session).to receive(:logged?).and_return(true).at_least(1).times
        expect(current_session).to receive(:has_rogers_account?).and_return(false).at_least(1).times
      end

      # /orders results in the same event
      context '/orders/new path' do
        let(:current_path) { '/orders/new' }

        it 'should add a billing info start event' do
          current_session.guid = 'fake-test-guid'
          params = { current_path: current_path, language: lang, session: session, current_session: current_session }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en new user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '3 billing info start'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
          expect(dlb.layers.first[:userId]).to eql 'fake-test-guid'
        end
      end

      # /orders/callback results in the same event
      context '/orders/summary path' do
        let(:current_path) { '/orders/summary' }

        it 'should add a confirm subscription event' do
          params = { current_path: current_path, language: lang, session: session, current_session: current_session }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en new user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '5 confirm subscription'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
        end

        it 'should not add any layers when the session has a valid redemption code' do
          redemption = double('promo_code')
          expect(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption

          params = { current_path: current_path, language: lang, session: session, current_session: current_session }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end

      context '/profiles path' do
        let(:current_path) { '/profiles' }

        context 'with new latest order & success notice' do
          let(:order) { double('order', order_id: 1234, status: 'new') }
          let(:profile) { double('profile', user_orders: [order], has_redemption?: false) }
          before { flash[:notice] = 'Order was successfully created.' }

          it 'should add a complete subscription event with a regular event label' do
            expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

            expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

            params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
            dlb = DataLayerBuilder.new params
            expect(dlb.layers.length).to eql 1
            expect(dlb.layers.first[:eventCategory]).to eql 'en new user funnel'
            expect(dlb.layers.first[:eventAction]).to eql '6 complete subscription'
            expect(dlb.layers.first[:eventLabel]).to eql 'basic : regular'
            expect(dlb.layers.first[:accountNumber]).to eql 1234
          end

          context 'with promo code in profile entitlements' do
            before { expect(profile).to receive(:promotion_code).and_return('testPromo1234').at_least(2).times }

            it 'should add a complete subscription event with a coupon event label' do
              expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

              expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

              params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
              dlb = DataLayerBuilder.new params
              expect(dlb.layers.first[:couponCode]).to eql 'testPromo1234'
              expect(dlb.layers.first[:eventLabel]).to eql 'basic : coupon'
            end
          end

          context 'with loyalty code in profile entitlements' do
            before do
              expect(profile).to receive(:loyalty_membership_number).and_return('2837691823761892376').at_least(2).times
              expect(profile).to receive(:loyalty_type).and_return('Air Miles').at_least(2).times
            end

            it 'should add a complete subscription event with a loyalty event label' do
              expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

              expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

              params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
              dlb = DataLayerBuilder.new params
              expect(dlb.layers.first[:loyaltyNumber]).to eql '2837691823761892376'
              expect(dlb.layers.first[:eventLabel]).to eql 'basic : loyalty : airmiles'
            end
          end
        end

        it 'should not add any layers without a flash notice' do
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end
    end
  end

  context 'setup_existing_user_funnel_layers' do
    context 'logged out' do
      context '/rogers_sign_in_or_up' do
        let(:current_path) { '/rogers_sign_in_or_up' }

        it 'should add a create account event' do
          params = { current_path: current_path, language: lang, session: session, current_session: nil }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '1 email existing or new'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
        end
      end
    end

    context 'logged on' do
      let(:current_session) { FactoryGirl.build(:session) }

      before do
        allow(current_session).to receive(:profile).and_return(ineligible_profile)
        expect(current_session).to receive(:logged?).and_return(true).at_least(1).times
        expect(current_session).to receive(:has_rogers_account?).and_return(true).at_least(1).times
      end

      # /orders results in the same event
      context '/orders/new path' do
        let(:current_path) { '/orders/new' }
        let(:order) { FactoryGirl.build(:order, billing_option: 'rogersbill') }

        it 'should add 2a add to bill or use card event when on the rogers billing option' do
          current_session.guid = 'fake-test-guid'
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '3a add to bill or use card'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
          expect(dlb.layers.first[:userId]).to eql 'fake-test-guid'
        end

        it 'should add 2b add card details event when on the credit card form' do
          current_session.guid = 'fake-test-guid'
          order.billing_option = 'cc'
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '3b add card details'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
          expect(dlb.layers.first[:userId]).to eql 'fake-test-guid'
        end
      end

      # /orders/callback results in the same event
      context '/orders/summary path' do
        let(:current_path) { '/orders/summary' }
        let(:order) { FactoryGirl.build(:order, billing_option: 'rogersbill') }

        it 'should add a confirm subscription event after submitting the rogers billing form' do
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '4 confirm subscription'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
        end

        it 'should add a confirm subscription event after submitting the credit card form' do
          order.billing_option = 'cc'
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
          expect(dlb.layers.first[:eventAction]).to eql '4 confirm subscription'
          expect(dlb.layers.first[:eventLabel]).to eql 'basic'
        end

        # This technically should not be possible anyways since the billing option would be 'free' for redemption code submission
        it 'should not add any layers when submitting the credit card form with a valid redemption code' do
          redemption = double('promo_code')
          order.billing_option = 'cc'
          expect(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption

          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end

        it 'should not add any layers when submitting the redemption form' do
          redemption = double('promo_code')
          order.billing_option = 'free'
          expect(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption

          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end

      context '/profiles path' do
        let(:current_path) { '/profiles' }

        context 'with new latest order & success notice' do
          let(:order) { double('order', order_id: 1234, status: 'new', billing_option: 'rogersbill') }
          let(:credit_order) { double('order', order_id: 1234, status: 'new', billing_option: 'cc') }
          let(:profile) { double('profile', user_orders: [order], has_redemption?: false) }
          before { flash[:notice] = 'Order was successfully created.' }

          it 'should add a complete subscription event with a regular event label' do
            expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

            expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

            params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
            dlb = DataLayerBuilder.new params
            expect(dlb.layers.length).to eql 1
            expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
            expect(dlb.layers.first[:eventAction]).to eql '5 complete subscription'
            expect(dlb.layers.first[:eventLabel]).to eql 'rogers billing : basic : regular'
            expect(dlb.layers.first[:accountNumber]).to eql 1234
          end

          it 'should add a complete subscription event with a card billing event label' do
            expect(current_session).to receive(:latest_order).and_return(credit_order).at_least(1).times

            expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

            params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
            dlb = DataLayerBuilder.new params
            expect(dlb.layers.length).to eql 1
            expect(dlb.layers.first[:eventCategory]).to eql 'en existing user funnel'
            expect(dlb.layers.first[:eventAction]).to eql '5 complete subscription'
            expect(dlb.layers.first[:eventLabel]).to eql 'card billing : basic : regular'
            expect(dlb.layers.first[:accountNumber]).to eql 1234
          end

          context 'with promo code in profile entitlements' do
            before { expect(profile).to receive(:promotion_code).and_return('testPromo1234').at_least(2).times }

            it 'should add a complete subscription event with a coupon event label' do
              expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

              expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

              params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
              dlb = DataLayerBuilder.new params
              expect(dlb.layers.first[:couponCode]).to eql 'testPromo1234'
              expect(dlb.layers.first[:eventLabel]).to eql 'rogers billing : basic : coupon'
            end
          end

          context 'with loyalty code in profile entitlements' do
            before do
              expect(profile).to receive(:loyalty_membership_number).and_return('2837691823761892376').at_least(2).times
              expect(profile).to receive(:loyalty_type).and_return('Air Miles').at_least(2).times
            end


            it 'should add a complete subscription event with a coupon event label' do
              expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

              expect(current_session).to receive(:profile).and_return(profile).at_least(1).times

              params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
              dlb = DataLayerBuilder.new params
              expect(dlb.layers.first[:loyaltyNumber]).to eql '2837691823761892376'
              expect(dlb.layers.first[:eventLabel]).to eql 'rogers billing : basic : loyalty : airmiles'
            end
          end
        end

        it 'should not add any layers without a flash notice' do
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end
    end
  end

  context 'setup_redemption_funnel_layers' do
    let(:redemption) { FactoryGirl.build(:redemption_code) }

    context 'logged out' do
      # / root path results in same event
      context '/redemption' do
        let(:current_path) { '/redemption' }

        it 'should add a enter redemption code event' do
          expect(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: nil }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'redemption funnel'
          expect(dlb.layers.first[:eventAction]).to eql '1 enter redemption code'
          expect(dlb.layers.first[:eventLabel]).to eql 'testcode1234'
        end

        it 'should add a enter redemption code event without a label if the user has not entered a valid redemption yet' do
          expect(redemption).to receive(:is_valid_redemption?).and_return(false)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: nil }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'redemption funnel'
          expect(dlb.layers.first[:eventAction]).to eql '1 enter redemption code'
          expect(dlb.layers.first[:eventLabel]).to eql ''
        end
      end

      context '/register' do
        let(:current_path) { '/register' }

        it 'should add a enter email event' do
          allow(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: nil }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1

          expect(dlb.layers[0][:eventCategory]).to eql 'redemption funnel'
          expect(dlb.layers[0][:eventAction]).to eql '2 enter email'
          expect(dlb.layers[0][:eventLabel]).to eql 'testcode1234'
        end

        it 'should not add a redemption event if the user has not entered a valid redemption yet' do
          allow(redemption).to receive(:is_valid_redemption?).and_return(false)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: nil }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to_not eql 'redemption funnel'
        end
      end
    end

    context 'logged on' do
      let(:current_session) { FactoryGirl.build(:session) }

      before do
        allow(current_session).to receive(:profile).and_return(ineligible_profile)
        expect(current_session).to receive(:logged?).and_return(true).at_least(1).times
        expect(current_session).to receive(:has_rogers_account?).and_return(false).at_least(1).times
      end

      context '/orders/promo_contact path' do
        let(:current_path) { '/orders/promo_contact' }
        let(:order) { FactoryGirl.build(:order, billing_option: 'free') }

        it 'should add enter personal details event with a valid redemption' do
          expect(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'redemption funnel'
          expect(dlb.layers.first[:eventAction]).to eql '4 enter personal details'
          expect(dlb.layers.first[:eventLabel]).to eql redemption.code
        end

        it 'should not add any events with an invalid redemption' do
          expect(redemption).to receive(:is_valid_redemption?).and_return(false)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end

      context '/orders/summary path' do
        let(:current_path) { '/orders/summary' }
        let(:order) { FactoryGirl.build(:order, billing_option: 'free') }

        it 'should not add any events when submitting the redemption form' do
          expect(redemption).to receive(:is_valid_redemption?).and_return(true)
          session[:promo_code] = redemption
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, order: order }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end

      context '/profiles path' do
        let(:current_path) { '/profiles' }

        context 'with new latest order & redemption applied success notice' do
          let(:order) { double('order', order_id: 1234, status: 'new') }
          let(:profile) { double('profile', user_orders: [order], has_redemption?: true, promotion_desc: 'test promotion here', promotion_code: 'test-promo-42') }
          before { flash[:notice] = 'Success your code has been applied.' }

          it 'should add a complete subscription event' do
            expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times

            expect(current_session).to receive(:profile).and_return(profile).at_least(1).times
            current_session.guid = 'fake-test-guid'

            params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
            dlb = DataLayerBuilder.new params
            expect(dlb.layers.length).to eql 1
            expect(dlb.layers[0][:eventCategory]).to eql 'redemption funnel'
            expect(dlb.layers[0][:eventAction]).to eql '5 complete subscription'
            expect(dlb.layers[0][:eventLabel]).to eql 'test-promo-42'
            expect(dlb.layers[0][:userId]).to eql 'fake-test-guid'
            expect(dlb.layers[0][:accountNumber]).to eql 1234
          end
        end

        it 'should not add any layers without a flash notice' do
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 0
        end
      end
    end
  end

  context 'setup_change_plan_layers' do
    context 'logged on' do
      let(:current_session) { FactoryGirl.build(:session) }
      before { expect(current_session).to receive(:logged?).and_return(true).at_least(1).times }

      context '/profiles path' do
        let(:current_path) { '/profiles' }
        let(:order) { FactoryGirl.build(:user_order) }

        it 'should add change plan event with a downgraded order status and downgraded flash notice' do
          flash[:notice] = 'Downgraded to basic'
          order.status = 'Downgraded'
          expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'change plan'
          expect(dlb.layers.first[:eventLabel]).to eql 'Downgraded'
        end

        it 'should add change plan event with an upgraded order status and upgraded flash notice' do
          flash[:notice] = 'Upgraded to premium'
          order.status = 'Upgraded'
          expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'change plan'
          expect(dlb.layers.first[:eventLabel]).to eql 'Upgraded'
        end

        it 'should add change plan event with a cancelled order status and cancel subscription flash notice when cancel survey flag is nil' do
          allow(Admin::FeatureFlag).to receive(:feature_flag).with(:cancel_survey).and_return(nil)
          flash[:notice] = 'Successfully cancelled your subscription'
          order.status = 'Cancelled'
          expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'change plan'
          expect(dlb.layers.first[:eventLabel]).to eql 'Cancelled'
        end

        it 'should add change plan event with a cancelled order status and cancel survey flash notice when cancel survey flag is true' do
          allow(Admin::FeatureFlag).to receive(:feature_flag).with(:cancel_survey).and_return('true')
          flash[:notice] = 'Sorry to see you go. Your cancellation will take place as of your next billing cycle ending on 22/04/2015.'
          order.status = 'Cancelled'
          expect(order).to receive(:next_billing_cycle_date).and_return(Date.new(2015,4,22)).at_least(1).times
          expect(current_session).to receive(:latest_order).and_return(order).at_least(1).times
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'change plan'
          expect(dlb.layers.first[:eventLabel]).to eql 'Cancelled'
        end

        it 'should add change plan event when applied promotion success notice is in flash' do
          flash[:notice] = I18n.t('cancel_order.successfully_applied_promo')
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'cancel survey'
          expect(dlb.layers.first[:eventLabel]).to eql 'saved_with_promo'
        end
      end

      context '/cancel_order_subscription path' do
        let(:current_path) { '/cancel_order_subscription' }

        it 'should add change plan event when cancel survey submission success notice is in flash' do
          flash[:notice] = I18n.t('cancel_order.submit_survey_success')
          session[:survey_selection] = 'test survey answers'
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'cancel survey'
          expect(dlb.layers.first[:eventLabel]).to eql 'test survey answers'
        end

        it 'should add skipped change plan event when cancel survey submission success notice is in flash and survey selection is blank' do
          flash[:notice] = I18n.t('cancel_order.submit_survey_success')
          session[:survey_selection] = ''
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'change plan'
          expect(dlb.layers.first[:eventAction]).to eql 'cancel survey'
          expect(dlb.layers.first[:eventLabel]).to eql 'skipped'
        end
      end
    end
  end

  context 'setup_key_website_action_layers' do
    let(:current_session) { FactoryGirl.build(:session) }

    context 'logged on' do
      before { expect(current_session).to receive(:logged?).and_return(true).at_least(1).times }

      context '/profiles path' do
        let(:current_path) { '/profiles' }

        it 'should add key website actions event when the successfully logged in flash notice is set' do
          flash[:notice] = 'Successfully logged in.'
          current_session.guid = 'fake-test-guid'
          params = { current_path: current_path, language: lang, session: session, current_session: current_session, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'key website actions'
          expect(dlb.layers.first[:eventAction]).to eql 'sign ins'
          expect(dlb.layers.first[:eventLabel]).to eql ''
          expect(dlb.layers.first[:userId]).to eql 'fake-test-guid'
        end
      end
    end

    context 'logged out' do
      context '/signin path' do
        let(:current_path) { '/signin' }

        it 'should add key website actions event when the legacy rogers user is automatically signed out' do
          flash[:alert] = I18n.t('sessions.notice.legacy_logged_out')
          params = { current_path: current_path, language: lang, session: session, current_session: nil, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 2
          expect(dlb.layers.first[:eventCategory]).to eql 'key website actions'
          expect(dlb.layers.first[:eventAction]).to eql 'errors'
          expect(dlb.layers.first[:eventLabel]).to eql 'Legacy rogers account sign in error'
        end
      end
    end
  end

  context 'setup_error_layers' do
    context 'unregistered' do
      context '/profiles path' do
        let(:current_path) { '/profiles' }

        it 'should add key website actions event when the successfully logged in flash notice is set' do
          flash[:alert] = 'Something went wrong.'
          params = { current_path: current_path, language: lang, session: session, current_session: nil, flash: flash }
          dlb = DataLayerBuilder.new params
          expect(dlb.layers.length).to eql 1
          expect(dlb.layers.first[:eventCategory]).to eql 'errors'
          expect(dlb.layers.first[:eventAction]).to eql 'error '
          expect(dlb.layers.first[:eventLabel]).to eql 'Something went wrong.'
        end
      end
    end
  end
end
