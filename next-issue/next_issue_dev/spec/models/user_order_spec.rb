
require 'spec_helper'

describe UserOrder do
  let(:user_order) { FactoryGirl.build(:user_order) }

  context '#basic?' do
    it 'return false when existing offer type is ultimate' do
      user_order.existing_offer_type = 'Ultimate'
      expect(user_order.basic?).to eql false
    end

    it 'return true when existing offer type is basic' do
      expect(user_order.basic?).to eql true
    end

    it 'return false when existing offer type is premium' do
      user_order.existing_offer_type = 'Premium'
      expect(user_order.basic?).to eql false
    end
  end

  context '#premium?' do
    it 'return false when existing offer type is ultimate' do
      user_order.existing_offer_type = 'Ultimate'
      expect(user_order.premium?).to eql false
    end

    it 'return true when existing offer type is premium' do
      user_order.existing_offer_type = 'Premium'
      expect(user_order.premium?).to eql true
    end

    it 'return false when existing offer type is basic' do
      expect(user_order.premium?).to eql false
    end
  end

  context '#description' do
    it 'return english description without params' do
      user_order.desc_en = 'some test description'
      expect(user_order.description).to eql 'some test description'
    end

    it 'return french description with fr' do
      user_order.desc_fr = 'some test description'
      expect(user_order.description('fr')).to eql 'some test description'
    end

    it 'return nil when not en or fr' do
      expect(user_order.description('something')).to eql nil
    end
  end

  context '#next_billing_cycle_date' do
    # activation_date 'Wed Jun 17 07:00:00 GMT 2015'
    context 'today is after activation date' do
      before { Timecop.freeze(Time.local(2015, 6, 19, 10, 5, 0)) }
      after { Timecop.return }

      it 'should return next month on the same day of the activation date' do
        next_billing = user_order.next_billing_cycle_date
        expect(next_billing.day).to eql 17
        expect(next_billing.month).to eql 7
        expect(next_billing.year).to eql 2015
      end
    end

    context 'today is before activation date' do
      before { Timecop.freeze(Time.local(2015, 6, 16, 10, 5, 0)) }
      after { Timecop.return }

      it 'should return today\'s month on the same day of the activation date' do
        next_billing = user_order.next_billing_cycle_date
        expect(next_billing.day).to eql 17
        expect(next_billing.month).to eql 6
        expect(next_billing.year).to eql 2015
      end
    end

    context 'activation date is Sunday May 31 07:00:00 GMT 2015' do
      before { user_order.activation_date = 'Sunday May 31 07:00:00 GMT 2015' }

      context 'today is on the same day as activation date' do
        before { Timecop.freeze(Time.local(2015, 7, 31, 10, 5, 0)) }
        after { Timecop.return }

        it 'should return this month on the same day of the activation date' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 31
          expect(next_billing.month).to eql 7
          expect(next_billing.year).to eql 2015
        end
      end

      context 'today is before activation date' do
        before { Timecop.freeze(Time.local(2015, 6, 16, 10, 5, 0)) }
        after { Timecop.return }

        it 'should return today\'s month on the last day of the month' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 30
          expect(next_billing.month).to eql 6
          expect(next_billing.year).to eql 2015
        end
      end

      context 'today is next year Feb 28th' do
        before { Timecop.freeze(Time.local(2016, 2, 28, 10, 5, 0)) }
        after { Timecop.return }

        it 'should return today\'s month on the last day of the month' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 29
          expect(next_billing.month).to eql 2
          expect(next_billing.year).to eql 2016
        end
      end
    end

    context 'activation date is Saturday Feb 28 07:00:00 GMT 2015' do
      before { user_order.activation_date = 'Saturday Feb 28 07:00:00 GMT 2015' }

      context 'today is on the same day as activation date' do
        before { Timecop.freeze(Time.local(2015, 7, 28, 10, 5, 0)) }
        after { Timecop.return }

        it 'should return this month on the same day of the activation date' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 28
          expect(next_billing.month).to eql 7
          expect(next_billing.year).to eql 2015
        end
      end

      context 'today is after day of activation date' do
        before { Timecop.freeze(Time.local(2015, 7, 30, 10, 5, 0)) }
        after { Timecop.return }

        it 'should return next month on the same day of the activation date' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 28
          expect(next_billing.month).to eql 8
          expect(next_billing.year).to eql 2015
        end
      end

      context 'today is before activation date' do
        before { Timecop.freeze(Time.local(2015, 6, 16, 10, 5, 0)) }
        after { Timecop.return }

        it 'should return today\'s month on day of the activation date' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 28
          expect(next_billing.month).to eql 6
          expect(next_billing.year).to eql 2015
        end
      end
    end

    context 'activation date is Tuesday Jan 1 01:00:00 GMT 2015' do
      before { user_order.activation_date = 'Tuesday Jan 1 01:00:00 GMT 2015' }

      context 'the time is 2014-12-31 23:30:10 -0500' do
        before { Timecop.freeze(Time.new(2014,12,31, 23,30,10,'-05:00')) }
        after { Timecop.return }

        it 'should return the activation date' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 1
          expect(next_billing.month).to eql 1
          expect(next_billing.year).to eql 2015
        end
      end

      context 'the time is 2015-01-01 23:30:10 -0500' do
        before { Timecop.freeze(Time.new(2015,1,1, 23,30,10,'-05:00')) }
        after { Timecop.return }

        it 'should return next month on the same day of the activation date' do
          # converting current time to gmt will push the date into tomorrow
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 1
          expect(next_billing.month).to eql 2
          expect(next_billing.year).to eql 2015
        end
      end
    end

    context 'activation date is Monday Feb 29 01:00:00 GMT 2016' do
      before { user_order.activation_date = 'Monday Feb 29 01:00:00 GMT 2016' }

      context 'the time is 2017-02-28 23:30:10 -0500' do
        before { Timecop.freeze(Time.new(2017,2,28, 23,30,10,'+05:00')) }
        after { Timecop.return }

        it 'should return last day of Feb' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 28
          expect(next_billing.month).to eql 2
          expect(next_billing.year).to eql 2017
        end
      end

      context 'the time is 2017-02-28 23:30:10 -0500' do
        before { Timecop.freeze(Time.new(2017,2,28, 23,30,10,'-05:00')) }
        after { Timecop.return }

        it 'should return same day as activation day in the next month' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 29
          expect(next_billing.month).to eql 3
          expect(next_billing.year).to eql 2017
        end
      end

      context 'the time is 2017-02-28 23:30:10 -0500' do
        before { Timecop.freeze(Time.new(2017,2,28, 23,30,10,'-05:00')) }
        after { Timecop.return }

        it 'should return the activation date' do
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 29
          expect(next_billing.month).to eql 3
          expect(next_billing.year).to eql 2017
        end
      end

      context 'the time is 2016-01-02 01:30:10 +0500' do
        before { Timecop.freeze(Time.new(2016,2,1, 1,30,10,'+05:00')) }
        after { Timecop.return }

        it 'should return the activation date' do
          # converting translates today's date to the activation date yesterday.
          next_billing = user_order.next_billing_cycle_date
          expect(next_billing.day).to eql 29
          expect(next_billing.month).to eql 2
          expect(next_billing.year).to eql 2016
        end
      end
    end
  end
end
