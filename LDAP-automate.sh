#!/bin/bash

#https://www.server-world.info/en/note?os=CentOS_7&p=openldap

#This is a basis for students to create a fully functioning build, compile, and deploy script.



yum -y install openldap-servers openldap-clients



cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG 

chown ldap. /var/lib/ldap/DB_CONFIG



systemctl enable slapd

systemctl start slapd



yum -y install httpd

yum -y install phpldapadmin

# some source editing

# Tell SE linux what's going on, so that it doesn't freek

setsebool -P httpd_can_connect_ldap on



systemctl enable httpd

systemctl start httpd



sed -i 's,Require local,#Require local\n    Require all granted,g' /etc/httpd/conf.d/phpldapadmin.conf



# decent config guide: http://www.itzgeek.com/how-tos/linux/centos-how-tos/install-configure-phpldapadmin-centos-7-ubuntu-16-04.html







#Note: LDAP comes up completely insecure, with Anonymous login enabled by default... this is not a good and happy thing, so fix 

#it in the config file

#(prompt for user input), the following is currently a manual config, but could be automated fairly easily

#slappasswd

#open tcp port 389

#
cp /etc/phpldapadmin/config.php /etc/phpldapadmin/config.php.orig

cp /tmp/hello-nti-310/config/config.php /etc/phpldapadmin/config.php

chown ldap:apache /etc/phpldapadmin/config.php

systemctl restart httpd.service

echo "phpldapadmin is now up and running:
echo "we are configuring ldap and ldapadmin"

#Generates and stores new passwd securely
newsecret=$(slappasswd -g)
newhash=$(slappasswd -s "$newsecret")
echo -n "$newsecret: > /root/ldap_admin_pass
chmod 0600 /root/ldap_admin_pass

echo -e "dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffic: dc=nti210,dc=local
\n
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=nti310,dc=local
\n
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: @newhash" > db.ldif

ldapmodicy -Y EXTERNAL -H ldapi:/// -f db.ldif
#Auth restriction






echo "dn: olcDatabase={2}hdb,cn=config

changetype: modify

replace: olcSuffix

olcSuffix: dc=nti310,dc=local

dn: olcDatabase={2}hdb,cn=config

changetype: modify

replace: olcRootDN

olcRootDN: cn=ldapadm,dc=nti310,dc=local

dn: olcDatabase={2}hdb,cn=config

changetype: modify

replace: olcRootPW

olcRootPW: $newhash" >> db.ldif



ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif



# Restrict auth



echo 'dn: olcDatabase={1}monitor,cn=config

changetype: modify

replace: olcAccess

olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=nti310,dc=local" read by * none' > monitor.ldif



ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif





# Generate certs



openssl req -new -x509 -nodes -out /etc/openldap/certs/nti310ldapcert.pem -keyout /etc/openldap/certs/nti310ldapkey.pem -days 365 -subj "/C=US/ST=WA/L=Seattle/O=SCC/OU=IT/CN=nti310.local"



chown -R ldap. /etc/openldap/certs/nti*.pem



# Use Certs in LDAP



echo "dn: cn=config

changetype: modify

replace: olcTLSCertificateFile

olcTLSCertificateFile: /etc/openldap/certs/nti310ldapcert.pem

dn: cn=config

changetype: modify

replace: olcTLSCertificateKeyFile

olcTLSCertificateKeyFile: /etc/openldap/certs/nti310ldapkey.pem" > certs.ldif



ldapmodify -Y EXTERNAL  -H ldapi:/// -f certs.ldif



# Test cert configuration



slaptest -u



unalias cp





ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif





# Create base group and people structure



echo "dn: dc=nti310,dc=local

dc: nti310

objectClass: top

objectClass: domain

dn: cn=ldapadm ,dc=nti310,dc=local

objectClass: organizationalRole

cn: ldapadm

description: LDAP Manager

dn: ou=People,dc=nti310,dc=local

objectClass: organizationalUnit

ou: People

dn: ou=Group,dc=nti310,dc=local

objectClass: organizationalUnit

ou: Group" > base.ldif



ldapadd -x -W -D "cn=ldapadm,dc=nti310,dc=local" -f base.ldif -y /root/ldap_admin_pass
