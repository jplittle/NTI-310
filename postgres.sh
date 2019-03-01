sudo su
yum install python-pip python-devel gcc postgresql-server postgresql-devel postgresql-contrib
postgresql-setup initdb
systemctl start postgresql
vim /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql
systemctl enable postgresql
sed -i 's,host  all     all   127.0.0.1/32    ident,host  all   all   127.0.0.1'
sed -i 's,host  all     all   ::1/128         ident,host  all   all   ::128'
echo "CREATE DATABASE myproject;	
CREATE USER myprojectuser WITH PASSWORD 'password';	
ALTER ROLE myprojectuser SET client_encoding TO 'utf8';	
ALTER ROLE myprojectuser SET default_transaction_isolation TO 'read committed';	
ALTER ROLE myprojectuser SET timezone TO 'UTC';	
GRANT ALL PRIVILEGES ON DATABASE myproject TO myprojectuser;" >> /tmp/tempfile	


sudo -u postgres /bin/psql -f /tmp/tempfile
