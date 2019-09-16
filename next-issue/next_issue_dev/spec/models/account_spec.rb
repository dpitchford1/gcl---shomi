require 'spec_helper'

describe Account do
  let(:account) { FactoryGirl.build(:account) }

  context '#account_desc' do
    it 'return account desc' do
      expect(account.account_desc).to eql 'test account'
    end

    it 'return account desc en when account desc is nil' do
      account.account_desc = nil
      account.account_desc_en = 'new test account'
      expect(account.account_desc).to eql 'new test account'
    end
  end
end
