sudo su
yum install python-pip python-devel gcc postgresql-server postgresql-devel postgresql-contrib
postgresql-setup initdb
systemctl start postgresql
# vim /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql
systemctl enable postgresql
sed -i 's,host    all             all             127.0.0.1               ident,host    all             all             127.0.0.1
sed -i 's,host    all             all             ::1/128                 ident,host    all             all             ::1/128

echo "CREATE DATABASE myproject;	
CREATE USER myprojectuser WITH PASSWORD 'password';	
ALTER ROLE myprojectuser SET client_encoding TO 'utf8';	
ALTER ROLE myprojectuser SET default_transaction_isolation TO 'read committed';	
ALTER ROLE myprojectuser SET timezone TO 'UTC';	
GRANT ALL PRIVILEGES ON DATABASE myproject TO myprojectuser;" >> /tmp/tempfile	


sudo -u postgres /bin/psql -f /tmp/tempfile
yum install -y httpd
systemctl start httpd
systemctl enable httpd
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_network_connect_db on
sudo yum install -y php php-pgsql

# vi /var/lib/pgsql/
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgressql.conf 
sed -i 's/#port = 5432/port = 5432/g' /var/lib/pgsql/data/postgresql.conf

echo "CREATE USER pgdbuser CREATEDB CREATEUSER ENCRYPTED PASSWORD 'pgdbpass';
CREATE DATABASE mypgdb OWNER pgdbuser;
GRANT ALL PRIVILEGES ON DATABASE mypgdb TO pgdbuser;" > /tmp/phpmyadmin

sudo -u postgres /bin/psql -f /tmp/phpmyadmin
yum install -y phpPgAdmin
sed -i 's/Require local/Requrie all granted/g' /etc/httpd/conf.d/phpPgAdmin.conf
sed -i 's/Deny from all/Allow from all/g' /etc/htptd/conf.d/phpPgAdmin.conf

sudo systemctl reload httpd.service
systemctl restart postgresql
# http://ip/phpPgAdmin
# un = pgduser
# pw = pgdpass