#!/bin/bash

yum install -y git
cd /tmp
# git clone https://github.com/jplittle/LDAP-automate.sh
git clone https://github.com/jplittle/NTI-310

yum -y install openldap-servers openldap-clients

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
#giving ownership from root to ldap bc ldap has to be owner of ldap daemon to get info
chown ldap. /var/lib/ldap/DB_CONFIG 

#ldap daemon
systemctl enable slapd
systemctl start slapd

#apache server
yum -y install httpd
yum -y install phpldapadmin

#Let's SELinux - know what is going on
#NSA to harden and secure Linux systems
#Apache connecct to ldap
setsebool -P httpd_can_connect_ldap on

systemctl enable httpd
syetmctl start httpd

#modifies our httpd.conf to access from external URL
sed -i 's,Require local,#Require local\n  Require all granted,g' /etc/httpd/conf.d/phpldapadmin.conf
unalias cp

#making backup in case something goes wrong
cp /etc/phpldapadmin/config.php /etc/phpldapadmin/config.php.orig

cp /tmp/NTI-310/config.php /etc/phpldapadmin/config.php
chown ldap:apache /etc/phpldapadmin/config.php

systemctl restart httpd.service

echo "phpldapadmin is now up and running"
echo "we are configuring ldap and ldap admin"

#Generates and stores new passwords & restricts only root user to read

newsecret="P@ssw0rd1"
newhash=$(slappasswd -s "$newsecret")
echo -n "$newsecret" > /root/ldap_admin_pass
chmod 0600 /root/ldap_admin_pass

#Becomes ldif and configures root domain
echo -e "dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=nti310,dc=local
\n
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=nti310,dc=local
\n
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $newhash" > db.ldif

ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif

#Auth restriction

echo 'dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=nti310,dc=local" read by * none' > monitor.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f monitor.ldif

#Generates Certs
openssl req -new -x509 -nodes -out /etc/openldap/certs/nti310ldapcert.pem -keyout /etc/openldap/certs/nti310ldapkey.pem -days 365 -subj "/C=US/ST=WA/L=Seattle/O=SCC/OU=IT/CN=nti310.local"

chown -R ldap. /etc/openldap/certs/nti*.pem

##Error [root@ldap-b tmp]# ldapmodify -Y EXTERNAL  -H ldapi:/// -f certs.ldif
#SASL/EXTERNAL authentication started
#SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
#SASL SSF: 0
#modifying entry "cn=config"
#ldap_modify: Other (e.g., implementation specific) error (80)
#Solved this error by switching 

echo -e "dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/nti310ldapkey.pem
\n
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/nti310ldapcert.pem" > certs.ldif
 
ldapmodify -Y EXTERNAL  -H ldapi:/// -f certs.ldif

#Test what certs are there: ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config | grep olcTLS
#Test to see if cert config works
slaptest -u
echo "it works"

unalias cp

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

#creates group and people structure base

echo -e "dn: dc=nti310,dc=local
dc: nti310
objectClass: top
objectClass: domain
\n
dn: cn=ldapadm,dc=nti310,dc=local
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager
\n
dn: ou=People,dc=nti310,dc=local
objectClass: organizationalUnit
ou: People
\n
dn: ou=Group,dc=nti310,dc=local
objectClass: organizationalUnit
ou: Group" > base.ldif

#Turn off SELinux to test
setenforce 0

#authenticate with this user and build org specifications from imported base.ldif
#authenticate sourcing from previously created passwd w -y
ldapadd -x -W -D "cn=ldapadm,dc=nti310,dc=local" -f base.ldif -y /root/ldap_admin_pass

#Create Groups
echo -e "# Generated by phpLDAPadmin (http://phpldapadmin.sourceforge.net) on January 25, 2019 3:08 am
# Version: 1.2.3
\n
version: 1
\n
# Entry 1: cn=towels,ou=Group,dc=nti310,dc=local
dn: cn=towels,ou=Group,dc=nti310,dc=local
cn: towels
gidnumber: 500
objectclass: posixGroup
objectclass: top
\n
# Entry 2: cn=42,ou=Group,dc=nti310,dc=local
dn: cn=42,ou=Group,dc=nti310,dc=local
cn: 42
gidnumber: 501
objectclass: posixGroup
objectclass: top
\n
# Entry 3: cn=hitchhiker,ou=Group,dc=nti310,dc=local
dn: cn=hitchhiker,ou=Group,dc=nti310,dc=local
cn: hitchhiker
gidnumber: 502
objectclass: posixGroup
objectclass: top" > /tmp/GroupAdd.ldif

ldapadd -x -W -D "cn=ldapadm,dc=nti310,dc=local" -f /tmp/GroupAdd.ldif -y /root/ldap_admin_pass

#Create users
echo -e "# Generated by phpLDAPadmin (http://phpldapadmin.sourceforge.net) on January 25, 2019 2:15 am
# Version: 1.2.3
\n
version: 1
\n
# Entry 1: cn=Doug Lasa,ou=People,dc=nti310,dc=local
dn: cn=Doug Lasa,ou=People,dc=nti310,dc=local
cn: Doug Lasa
gidnumber: 500
givenname: Bob
homedirectory: /home/dlasa
loginshell: /bin/sh
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Lasa
uid: dlasa
uidnumber: 1000
userpassword: {SHA}IjmeQt7XATM3GuSJWO44Jkd+d2g=
\n
# Entry 2: cn=Bob Miller,ou=People,dc=nti310,dc=local
dn: cn=Bob Miller,ou=People,dc=nti310,dc=local
cn: Bob Miller
gidnumber: 501
givenname: Bob
homedirectory: /home/bmiller
loginshell: /bin/sh
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Miller
uid: bmiller
uidnumber: 1001
userpassword: {SHA}IjmeQt7XATM3GuSJWO44Jkd+d2g=
\n
# Entry 3: cn=Boy Kitten,ou=People,dc=nti310,dc=local
dn: cn=Boy Kitten,ou=People,dc=nti310,dc=local
cn: Boy Kitten
gidnumber: 502
givenname: Boy
homedirectory: /home/bkitten
loginshell: /bin/sh
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Kitten
uid: bkitten
uidnumber: 1002
userpassword: {SHA}IjmeQt7XATM3GuSJWO44Jkd+d2g=
\n
# Entry 4: cn=Apple Orange,ou=People,dc=nti310,dc=local
dn: cn=Apple Orange,ou=People,dc=nti310,dc=local
cn: Apple Orange
gidnumber: 500
givenname: Apple
homedirectory: /home/aorange
loginshell: /bin/sh
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Orange
uid: aorange
uidnumber: 1003
userpassword: {SHA}IjmeQt7XATM3GuSJWO44Jkd+d2g=
\n
# Entry 5: cn=Depressed Robot,ou=People,dc=nti310,dc=local
dn: cn=Depressed Robot,ou=People,dc=nti310,dc=local
cn: Depressed Robot
gidnumber: 502
givenname: Depressed
homedirectory: /home/drobot
loginshell: /bin/sh
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Robot
uid: drobot
uidnumber: 1004
userpassword: {SHA}IjmeQt7XATM3GuSJWO44Jkd+d2g=
\n
# Entry 6: cn=Zaphod Beeblebrox,ou=People,dc=nti310,dc=local
dn: cn=Zaphod Beeblebrox,ou=People,dc=nti310,dc=local
cn: Zaphod Beeblebrox
gidnumber: 502
givenname: Zaphod
homedirectory: /home/zbeeblebrox
loginshell: /bin/sh
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Beeblebrox
uid: zbeeblebrox
uidnumber: 1005
userpassword: {SHA}IjmeQt7XATM3GuSJWO44Jkd+d2g=" > /tmp/UserAdd.ldif

ldapadd -x -W -D "cn=ldapadm,dc=nti310,dc=local" -f /tmp/UserAdd.ldif -y /root/ldap_admin_pass

systemctl restart httpd


#client automation
sudo yum update -y && yum install -y rsyslog 	
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
# on the client add to end of file
echo "*.* @@rsyslog-server-final:514" >> /etc/rsyslog.conf
sudo systemctl status rsyslog
tail -f /var/log/messages
