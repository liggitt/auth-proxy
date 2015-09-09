# Clone from the Fedora 22 image
FROM fedora:22

MAINTAINER Jordan Liggitt <jliggitt@redhat.com>

# Install Kerberos, mod_auth_kerb
RUN dnf install -y \
  krb5-libs \
  krb5-server \
  krb5-workstation \
  pam_krb5 \
  httpd \
  apr-util-openssl \
  mod_auth_gssapi \
  mod_session \
  mod_ssl \
  && dnf clean all

# Add conf files for Kerberos
ADD krb5.conf /etc/krb5.conf
ADD kdc.conf  /var/kerberos/krb5kdc/kdc.conf
ADD kadm5.acl /var/kerberos/krb5kdc/kadm5.acl

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
