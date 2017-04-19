# Clone from the Fedora 23 image
FROM fedora:23

MAINTAINER Jordan Liggitt <jliggitt@redhat.com>

# Install Kerberos, mod_auth_kerb
RUN dnf install -y \
  apr-util-openssl \
  authconfig \
  httpd \
  krb5-libs \
  krb5-server \
  krb5-workstation \
  php \
  mod_php \
  mod_auth_gssapi \
  mod_auth_kerb \
  mod_auth_mellon \
  mod_intercept_form_submit \
  mod_session \
  mod_ssl \
  pam_krb5 \
  && dnf clean all

# Add conf files for Kerberos
ADD krb5.conf /etc/krb5.conf
ADD kdc.conf  /var/kerberos/krb5kdc/kdc.conf
ADD kadm5.acl /var/kerberos/krb5kdc/kadm5.acl
ADD httpd-pam /etc/pam.d/httpd-pam

# Add mod_auth_mellon setup script
ADD mellon_create_metadata.sh /usr/sbin/mellon_create_metadata.sh

# Add conf file for Apache
ADD proxy.conf /etc/httpd/conf.d/proxy.conf

# Add form login files
ADD login.php /var/www/html/login/index.php
ADD logout.php /var/www/html/logout/index.php

# 80  = http
# 443 = https
# 88  = kerberos
EXPOSE 80 443 88 88/udp

ADD configure /usr/sbin/configure
ENTRYPOINT /usr/sbin/configure
