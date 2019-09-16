class Account < Portal
  attribute :account_desc
  attribute :account_token
  attribute :account_desc_en
  attribute :account_desc_fr
  attribute :account_type_en
	attribute :account_type_fr
  attribute :billing_address_province
  attribute :billing_address_postal_code
  

  index :account_desc
  index :account_token

  def account_desc
		attributes[:account_desc] ||attributes[:account_desc_en]
	end

end
