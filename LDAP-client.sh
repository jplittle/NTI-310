#!/bin/bash
# based off of https://www.tecmint.com/configure-ldap-client-to-connect-external-authentication
# with some additions that make it work, as opposed to not work

# Updates list of repositories
apt-get update 
# What we are using for automation, to read all of this into debconf
apt-get install -y debconf-utils
# Disables pop-up screen
export DEBIAN_FRONTEND=noninteractive
# install all LDAP utlities
apt-get --yes install libnss-ldap libpam-ldap ldap-utils nscd
#go back to original functionality
unset DEBIAN_FRONTEND
# Into temp file
echo "ldap-auth-config ldap-auth-config/bindpw password
nslcd nslcd/ldap-bindpw password
ldap-auth-config ldap-auth-config/rootbindpw password
ldap-auth-config ldap-auth-config/move-to-debconf boolean true
nslcd nslcd/ldap-sasl-krb5-ccname string /var/run/nslcd/nslcd.tkt
nslcd nslcd/ldap-starttls boolean false
libpam-runtime libpam-runtime/profiles multiselect unix, ldap, systemd, capability
nslcd nslcd/ldap-sasl-authzid string
ldap-auth-config ldap-auth-config/rootbinddn string cn=ldapadm,dc=nti310,dc=local
nslcd nslcd/ldap-uris string ldap://ldap2 
nslcd nslcd/ldap-reqcert select
nslcd nslcd/ldap-sasl-secprops string
ldap-auth-config ldap-auth-config/ldapns/ldap_version select 3
ldap-auth-config ldap-auth-config/binddn string cn=proxyuser,dc=example,dc=net
nslcd nslcd/ldap-auth-type select none
nslcd nslcd/ldap-cacertfile string /etc/ssl/certs/ca-certificates.crt
nslcd nslcd/ldap-sasl-realm string
ldap-auth-config ldap-auth-config/dbrootlogin boolean true
ldap-auth-config ldap-auth-config/override boolean true
nslcd nslcd/ldap-base string dc=nti310,dc=local
ldap-auth-config ldap-auth-config/pam_password select md5
nslcd nslcd/ldap-sasl-mech select
nslcd nslcd/ldap-sasl-authcid string
ldap-auth-config ldap-auth-config/ldapns/base-dn string dc=nti310,dc=local
ldap-auth-config ldap-auth-config/ldapns/ldap-server string ldap://ldap2/
nslcd nslcd/ldap-binddn string
ldap-auth-config ldap-auth-config/dblogin boolean false" >> tempfile
#while is looking thorugh temp file, pipes it to debconf selections so our selections get set in debconf
while read line; do echo "$line" | debconf-set-selections; done < tempfile
# echoing pass into secret
echo "FZB/NbBu" > /etc/ldap.secret
# only read write by root
chown 600 /etc/ldap.secret
# confgiures client to use LDAP
sudo auth-client-config -t nss -p lac_ldap
# makes it so that we don't have to use a password to su to differen users
echo "account sufficient pam_succeed_if.so uid = 0 use_uid quiet" >> /etc/pam.d/su
# restarting nscd, enabling nscd
systemctl restart nscd
systemctl enable nscd
