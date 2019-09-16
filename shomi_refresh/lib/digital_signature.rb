require 'openssl'


#
# DigitalSignature is responsible for generating and verifying digital
# signatures.
#
# This is a tiny class that simply forwards sign and verify requests to a
# passed key.  This class mainly exists as a place to specify the hashing
# algorithm (digest) used to hash the documents being signed/verified.
#
# This class also Base64 encodes generated signatures and decodes passed
# signatures. It could be argued that this responsibility should not reside
# here but since the signatures are always passed around in ascii form by this
# application, it made sense to simpy do the encoding/decoding here.
#
module DigitalSignature
  def self.sign(document, private_key)
    Base64.encode64(private_key.sign(digest(), document))
  end

  def self.verify(document, signature, public_key)
    public_key.verify(digest(), Base64.decode64(signature), document)
  end

  # Public for unit testing purposes.
  def self.digest
    OpenSSL::Digest::SHA256.new
  end
end
