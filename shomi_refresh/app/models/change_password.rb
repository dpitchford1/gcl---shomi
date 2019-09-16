class ChangePassword < Portal
  attr_accessor :new_password

  validates_presence_of :new_password
  validates_confirmation_of :new_password
  validates_length_of :new_password, minimum: 7, maximum: 16
  validates_format_of :new_password, with: /\A(?=.*[0-9])(?=.*[a-zA-Z])[a-zA-Z0-9]+\z/
end