require_relative '../../test_helper'


class DigitalSignatureTest < ActiveSupport::TestCase ; end


#
# DigitalSignature.sign(document, private_key) => signature as an ascii string
#
class DigitalSignatureTest
  test "#sign uses 'private_key' arg to sign 'document' arg" do
    document = 'my document'
    private_key = generate_private_key()
    signature = DigitalSignature.sign(document, private_key)
    assert private_key.verify(DigitalSignature.digest, Base64.decode64(signature), document)
  end
end


#
# DigitalSignature.verify(document, signature, public_key) => true/false
#
class DigitalSignatureTest
  test "#verify returns true if the signture is valid" do
    document = 'my document'
    private_key = generate_private_key()
    signature = private_key.sign(DigitalSignature.digest, document)
    assert DigitalSignature.verify(document, Base64.encode64(signature), private_key.public_key)
  end

  test "#verify returns false if the signature is invalid" do
    document = 'my document'
    private_key = generate_private_key()
    signature = private_key.sign(DigitalSignature.digest, 'another document')
    assert !DigitalSignature.verify(document, signature, private_key.public_key)
  end
end


class DigitalSignatureTest
  private

  def generate_private_key()
    OpenSSL::PKey::RSA.new(2048)
  end
end
