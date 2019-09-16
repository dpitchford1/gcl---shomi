module DefaultRails
  class Application

    # Use #to_prepare so that these settings are not lost when
    # rails reloads the application in development mode.
    # See http://edgeguides.rubyonrails.org/configuring.html#initialization-events
    config.to_prepare do
      if Rails.env.development? or Rails.env.test?

        ENV['single_signon_private_key'] = <<-END_OF_PRIVATE_KEY
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA6AyAowz80rY7Pz2GMMtHDGjbZiktwG/JgNh9nALlhkY6Fy4N
3U2C70b5FcH3PnLcq69vObFIdZovnsUoAY9FEh6lgfPBsB5z93CJI3Dv1kIlvm/6
ckib3tcbllmX81o6QHUeE/j8SQ3fj+AK/c3l5L9ZGBf1nZmmmSGJHUG92skF4iDi
Imhkeb9bnj2WTq+jz+tC/PbjggVGH675eEdrh0TmXtLkBFgliwaHZErpurIyZddg
cC2FWXNWNPSfZVvsi8AHfSEwdLU3p9R/wYVGNz3KsLE+9TbFRmk1b6QGTJj3r0Vq
eHlWCFppI4mfMd36iMPxSMJWM9Ijuqh4xDpWBwIDAQABAoIBAF+UFsASL2jTKqAn
xUf/0qnn3sa7m16yLLtncIV8I/IkpvS5QXiv3oiUITC3DhGo2f/VaOjIfuIBui+Z
YZsS2g5WlTFrp5HVWUrIDZSNhhwobsd79BpykdE9pN1O1emkdm3qT5NGcRPeJQFr
9NsJnfGUZywnYkGh8h8M0x873uloLpGOH5ddrnXxPSfuNpz7Ux1kZzcqTVY436J5
egki3YmPkXPGpvM+py2DqpQgvXQX/y/jpmebYVmRhPyreWKRuvUFXnMrJv0SrQPO
gkM8NZgRI8r8ErUBd5NDpYgeV+hMzLLMJqsOalBdtKD2BfBt+HWCrtjRvNfDqHKE
GGTOGcECgYEA/gwNiiYdLsLBGLxuZukoWX1amOUg+HIvL3TUEzPkoZXpusN9acul
V1hmY5iuwEZyQSJSNhtcCNildZFEF7rEyHFZPISuyQ8lrRUFS4PIGsKa7fbDfZdf
4DmtCpmgoGklPKKzp+I/KB6PSa/fMtHh1tr9pba901ejpVMG1AkPdFcCgYEA6dUo
mFO4bKqSkv0DpKjJY9h1f2bu7mBLBcYZsely3dqy5yQ4EkhGNuBDFgIXF5kbs/aB
aDWU1tW2Ru13r06vEClYNkz36ZD60Z600e/MX6G21gK+uDutim/FIZnoUAg935Vt
sImfbp8yAqdAENqgpvl7EWcbuu6JfwxMn7v1ndECgYEA4Ao5FpAuREK0j9/9bPxJ
/UGzWAsZXIE2Y5+gN58YDfhrO62TOG3DzpfDFCpeUmrN7+sYnWbbb2G/6ULGzjaD
vFFZ5SkOC3o0O8PB+6qoGhFtGFb6aBPLFa9Hj4WURmLz19mUnoXENNlefBmBuQun
IxfVgQL7vRoY03+5Ed07p9kCgYEA4jugphhCE6jIXTw8PSAskNSJgbTmMG2ryC9N
BuvVfb4tXyKUuWOBw3Agl/d3vhYdTnWN6HQGyABG9cKlDFC1YY6O0SKQrULe2NaT
HZbDhjbgvZg0S+05TvoqoQLWWDBRJLPfR3EvdojBiv2kJ2pPCp3Pqxu2IZrOHsSY
keb5kTECgYEAx8eFEvxSfNkgnTTjDzxxr+IALJbn16yW0S3ZbyR+Xzm6zZs31TQ0
yAGcbO5I0JwTHmIu7J8pwmfgtN+EI0rITvmry2TjzGJsf0fT2yofVC0B/IDo4rqB
EUUJxsNXBfXg89Y48EoxoHdrAfPq9V3hgnEWG1P9g449pfK6I304+kE=
-----END RSA PRIVATE KEY-----
        END_OF_PRIVATE_KEY

      end
    end
  end
end
