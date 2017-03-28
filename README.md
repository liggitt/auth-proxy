# Auth Proxy

## Overview

This repo and Docker image provides a test proxy server, configured with Kerberos, Basic, Form and SAML authentication.

To start, run like this:
```
docker run -p 80:80 -p 443:443 -p 88:88 -h auth.example.com -e BACKEND=https://api.example.com:8443 -ti liggitt/auth-proxy
```

Invocation details:
* 80 is the http proxy port
* 443 is the https proxy port
* 88 is the Kerberos ticket server port
* `auth.example.com` can be replaced with any hostname you like, just adjust the setup instructions appropriately
* `$BACKEND` should be set to the base URL you want proxied (with no trailing slash). The host or IP must be accessible from within the container (so `localhost` probably won't work)

On startup, it sets up the following:
* Kerberos ticket server for `$PROXY_HOST` (defaulting to the host `auth.example.com` and the realm `AUTH.EXAMPLE.COM`)
* Apache proxy from `https://$PROXY_HOST/mod_auth_gssapi/*` to `$BACKEND`, secured by negotiate auth backed by Kerberos (mod_auth_gssapi)
* Apache proxy from `https://$PROXY_HOST/mod_auth_gssapi_basic/*` to `$BACKEND`, secured by negotiate auth backed by Kerberos (mod_auth_gssapi) with basic auth fallback
* Apache proxy from `https://$PROXY_HOST/mod_auth_kerb/*` to `$BACKEND`, secured by negotiate auth backed by Kerberos (mod_auth_kerb)
* Apache proxy from `https://$PROXY_HOST/mod_auth_kerb_basic/*` to `$BACKEND`, secured by negotiate auth backed by Kerberos (mod_auth_kerb) with basic auth fallback
* Apache proxy from `https://$PROXY_HOST/mod_auth_basic/*` to `$BACKEND`, secured by basic auth backed by Kerberos
* Apache proxy from `https://$PROXY_HOST/mod_auth_form/*` to `$BACKEND`, secured by form auth backed by a htpasswd file
* Apache proxy from `https://$PROXY_HOST/mod_auth_mellon/*` to `$BACKEND`, secured by SAML auth with the IDP metadata in /etc/httpd/conf.d/saml_idp.xml
* Apache proxy from `https://$PROXY_HOST/mod_intercept_form_submit/*` to `$BACKEND`, secured by form interception auth backed by Kerberos
* 5 test users, user1-user5@REALM, with password `password` (e.g. `user1@AUTH.EXAMPLE.COM`/`password`)

# Docker image setup

### Build the Docker image from source

```
make build
```

### Run the Docker image from source

Specify the backend to proxy to with the `$BACKEND` envvar.

```
BACKEND=https://api.example.com:8443 PROXY_HOST=auth.example.com make run
```

## Desktop setup

### Use the container as a Kerberos ticket server

The following examples assume `$PROXY_HOST` was set to `auth.example.com`, and the `krb5-workstation` package is installed.

1. Alias `auth.example.com` to the Docker IP in `/etc/hosts/:

  ```
  172.17.42.1 auth.example.com
  ```

2. Configure Kerberos to use the container as the ticket server in `/etc/krb5.conf`:

  ```
  [realms]
  AUTH.EXAMPLE.COM = {
    kdc = auth.example.com
    admin_server = auth.example.com
    default_domain = auth.example.com
  }
  
  [domain_realm]
  .auth.example.com = AUTH.EXAMPLE.COM
  auth.example.com = AUTH.EXAMPLE.COM
  ```

3. Configure Firefox to use negotiate auth with the domain:

  1. Type `about:config`
  2. Set `network.negotiate-auth.trusted-uris` to include `auth.example.com`
  
## Example Use

### Kerberos

The following examples assume `$PROXY_HOST` was set to `auth.example.com`, and the `krb5-workstation` package is installed.

1. Log in:

  ```
  $ kinit user1@AUTH.EXAMPLE.COM
  Password for user1@AUTH.EXAMPLE.COM: password

  $ klist
  Ticket cache: KEYRING:persistent:1000:1000
  Default principal: user1@AUTH.EXAMPLE.COM

  Valid starting       Expires              Service principal
  09/07/2015 20:43:32  09/08/2015 20:43:32  krbtgt/AUTH.EXAMPLE.COM@AUTH.EXAMPLE.COM
  ```

2. Check negotiate auth:
 
  ```
  $ curl -v http://auth.example.com/mod_auth_gssapi/ --negotiate -u :

  * Connected to auth.example.com (172.17.42.1) port 80 (#0)
  > GET /mod_auth_gssapi/ HTTP/1.1
  > Host: auth.example.com
  > Accept: */*

  < HTTP/1.1 401 Unauthorized
  < WWW-Authenticate: Negotiate

  * Issue another request to this URL: 'http://auth.example.com/mod_auth_gssapi/'
  * Server auth using GSS-Negotiate with user ''

  > GET /mod_auth_gssapi/ HTTP/1.1
  > Authorization: Negotiate YIICmQYGKwYBBQUCoIICj...
  > Host: auth.example.com
  > Accept: */*

  < HTTP/1.1 200 OK
  < WWW-Authenticate: Negotiate oYG3MIG0oAMKAQChCwYJK...
  < Content-Type: text/html
  < Content-Length: 252
  ...
  ```

3. Log out, verify no tickets are active

  ```
  $ kdestroy
  $ klist
  klist: Credentials cache keyring 'persistent:1000:1000' not found

  ```

4. Verify negotiate auth fails:

  ```
  $ curl -v http://auth.example.com/mod_auth_gssapi/ --negotiate -u :

  > GET /mod_auth_gssapi/ HTTP/1.1
  > Host: auth.example.com
  > Accept: */*

  < HTTP/1.1 401 Unauthorized
  < WWW-Authenticate: Negotiate
  * gss_init_sec_context() failed: : SPNEGO cannot find mechanisms to negotiate
  ...
  ```

### Basic auth

1. Check basic auth fails:
 
  ```
  $ curl -v http://auth.example.com/mod_auth_basic/ -u test:user

  * Server auth using Basic with user 'test'
  > GET /mod_auth_basic/ HTTP/1.1
  > Authorization: Basic dGVzdDp1c2Vy
  > Host: auth.example.com
  > Accept: */*

  < HTTP/1.1 401 Unauthorized
  * Authentication problem. Ignoring this.
  < WWW-Authenticate: Basic realm="Basic Login"
  ...

  ```

2. Check basic auth succeeds:
 
  ```
  $ curl -v http://auth.example.com/mod_auth_basic/ -u user1@AUTH.EXAMPLE.COM:password

  * Server auth using Basic with user 'user1@AUTH.EXAMPLE.COM'
  > GET /mod_auth_basic/ HTTP/1.1
  > Authorization: Basic dXNlcjFATVlET01BSU4uQ09NOnBhc3N3b3Jk
  > Host: auth.example.com
  > Accept: */*

  < HTTP/1.1 200 OK
  < Content-Type: text/html
  < Content-Length: 252
  ...
  ```

### SAML auth

1. Copy your IDP's metadata XML to /etc/httpd/conf.d/saml_idp.xml and restart httpd (`httpd -k restart`)

2. An example IDP can be created at https://auth0.com/. After creating an account, edit the default app's *Addons > SAML2 Web App* settings as follows:

    *Settings > Application Callback URL*: https://auth.example.com/mellon/postResponse

    *Settings > Settings*: 
    ```
    {
        "audience":  "https://auth.example.com",
        ...
    }
    ```

    *Usage > Identity Provider Metadata*: Copy to /etc/httpd/conf.d/saml_idp.xml in your proxy image and restart httpd (`httpd -k restart`) 