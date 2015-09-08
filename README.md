# Auth Proxy

## Overview

This repo and Docker image provides a test proxy server, configured with Kerberos, Basic and Form authentication.

On startup, it sets up the following
* Kerberos ticket server for `$PROXY_HOST` (defaulting to the host `mydomain.com` and the realm `MYDOMAIN.COM`)
* Apache proxy from `http://$PROXY_HOST:80/negotiate/*` to `$BACKEND`, secured with Kerberos auth
* Apache proxy from `http://$PROXY_HOST:80/basic/*` to `$BACKEND`, secured with basic auth
* Apache proxy from `http://$PROXY_HOST:80/form/*` to `$BACKEND`, secured with form auth
* 5 test users, user1-user5@REALM, with password `password` (e.g. `user1@MYDOMAIN.COM`/`password`)

# Docker image setup

### Build the Docker image from source

```
make build
```

### Run the Docker image from source

Specify the backend to proxy to with the `$BACKEND` envvar.

```
BACKEND=https://my-backend.com PROXY_HOST=mydomain.com make run
```

## Desktop setup

### Use the container as a Kerberos ticket server

The following examples assume `$PROXY_HOST` was set to `mydomain.com`, and the `krb5-workstation` package is installed.

1. Alias `mydomain.com` to the Docker IP in `/etc/hosts/:

  ```
  172.17.42.1 mydomain.com
  ```

2. Configure Kerberos to use the container as the ticket server in `/etc/krb5.conf`:

  ```
  [realms]
  MYDOMAIN.COM = {
    kdc = mydomain.com
    admin_server = mydomain.com
    default_domain = mydomain.com
  }
  
  [domain_realm]
  .mydomain.com = MYDOMAIN.COM
  mydomain.com = MYDOMAIN.COM
  ```

3. Configure Firefox to use negotiate auth with the domain:

  1. Type `about:config`
  2. Set `network.negotiate-auth.trusted-uris` to include `mydomain.com`
  
## Example Use

### Kerberos

The following examples assume `$PROXY_HOST` was set to `mydomain.com`, and the `krb5-workstation` package is installed.

1. Log in:

  ```
  $ kinit user1@MYDOMAIN.COM
  Password for user1@MYDOMAIN.COM: password

  $ klist
  Ticket cache: KEYRING:persistent:1000:1000
  Default principal: user1@MYDOMAIN.COM

  Valid starting       Expires              Service principal
  09/07/2015 20:43:32  09/08/2015 20:43:32  krbtgt/MYDOMAIN.COM@MYDOMAIN.COM
  ```

2. Check negotiate auth:
 
  ```
  $ curl -v http://mydomain.com/negotiate/ --negotiate -u :

  * Connected to mydomain.com (172.17.42.1) port 80 (#0)
  > GET /negotiate/ HTTP/1.1
  > Host: mydomain.com
  > Accept: */*

  < HTTP/1.1 401 Unauthorized
  < WWW-Authenticate: Negotiate

  * Issue another request to this URL: 'http://mydomain.com/negotiate/'
  * Server auth using GSS-Negotiate with user ''

  > GET /negotiate/ HTTP/1.1
  > Authorization: Negotiate YIICmQYGKwYBBQUCoIICj...
  > Host: mydomain.com
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
  $ curl -v http://mydomain.com/negotiate/ --negotiate -u :

  > GET /negotiate/ HTTP/1.1
  > Host: mydomain.com
  > Accept: */*

  < HTTP/1.1 401 Unauthorized
  < WWW-Authenticate: Negotiate
  * gss_init_sec_context() failed: : SPNEGO cannot find mechanisms to negotiate
  ...
  ```

### Basic auth

1. Check basic auth fails:
 
  ```
  $ curl -v http://mydomain.com/basic/ -u test:user

  * Server auth using Basic with user 'test'
  > GET /basic/ HTTP/1.1
  > Authorization: Basic dGVzdDp1c2Vy
  > Host: mydomain.com
  > Accept: */*

  < HTTP/1.1 401 Unauthorized
  * Authentication problem. Ignoring this.
  < WWW-Authenticate: Basic realm="Basic Login"
  ...

  ```

2. Check basic auth succeeds:
 
  ```
  $ curl -v http://mydomain.com/basic/ -u user1@MYDOMAIN.COM:password

  * Server auth using Basic with user 'user1@MYDOMAIN.COM'
  > GET /basic/ HTTP/1.1
  > Authorization: Basic dXNlcjFATVlET01BSU4uQ09NOnBhc3N3b3Jk
  > Host: mydomain.com
  > Accept: */*

  < HTTP/1.1 200 OK
  < Content-Type: text/html
  < Content-Length: 252
  ...
  ```
