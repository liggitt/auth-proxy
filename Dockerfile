# Clone from the Fedora 22 image
FROM fedora:22

MAINTAINER Jordan Liggitt <jliggitt@redhat.com>

# Install Kerberos, mod_auth_kerb
RUN dnf install -y \
  apr-util-openssl \
  authconfig \
  httpd \
  krb5-libs \
  krb5-server \
  krb5-workstation \
  mod_auth_gssapi \
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

# Add conf file for Apache
ADD proxy.conf /etc/httpd/conf.d/proxy.conf

# Add form login files
ADD login.html /var/www/html/login.html

# 80  = http
# 443 = https
# 88  = kerberos
EXPOSE 80 443 88 88/udp

ADD configure /usr/sbin/configure
ENTRYPOINT /usr/sbin/configure
