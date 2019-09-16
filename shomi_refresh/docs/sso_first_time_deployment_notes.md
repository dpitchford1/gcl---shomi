##### SSO (Single-Sign-On) First-time Deployment Notes

Perform these steps in each environment (integration, staging, production):

1. Generate a private key pair:

    ```
    $ openssl genrsa -out private.pem 2048
    ```

1. Extract the public key from the private key generated above:

    ```
    $ openssl rsa -in private.pem -pubout > public.pem
    ```

1. Set the following environment variables (examples use Heroku) on all portal sites (GCL, shomi, and nextissue).  In paricular, it is mandatory that the same private key be used on all sites within an environment (integration, staging, production), but that different keys be used for each environement:

    ```
    $ heroku config:set sso_enabled=true                              # false to disable
    $ heroku config:set nhl_sso_url=http://www.nhl.com/sso            # change to what nhl provides
    $ heroku config:set sso_timestamp_expiry_seconds=180              # +/- 3 minute window
    $ heroku config:set gcl_url=https://gamecentrelive.rogers.com     # adjust for int, staging, etc.
    $ heroku config:set shomi_url=http://www.shomi.com                # adjust for int, staging, etc.
    $ heroku config:set nextissue_url=http://www.nextissue.ca         # adjust for int, staging, etc.
    $ heroku config:set single_signon_private_key="`cat private.pem`"
    ```

1. Delete the private key generated above:

    ```
    $ rm private.pem
    ```

1. Provide public.pem to any sites that we sso into (e.g. possibly nhl.com).

1. Deploy the application.

References:
- [openssl commands](https://www.openssl.org/docs/apps/openssl.html)
- [openssl genrsa](https://www.openssl.org/docs/apps/genrsa.html)
- [openssl rsa](https://www.openssl.org/docs/apps/rsa.html)
- [Setting environment variables in Heroku](https://devcenter.heroku.com/articles/config-vars)
