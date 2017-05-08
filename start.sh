#!/bin/bash

#Mail configuration
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
apt-get install -y libsasl2-2 libsasl2-modules ca-certificates
echo "relayhost = [smtp.gmail.com]:587" >> /etc/postfix/main.cf
echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> /etc/postfix/main.cf
echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
echo "smtp_tls_CAfile = /etc/postfix/cacert.pem" >> /etc/postfix/main.cf
echo "smtp_use_tls = yes" >> /etc/postfix/main.cf
touch /etc/postfix/sasl_passwd && echo "[smtp.gmail.com]:587    $SMTP_MAIL:$SMTP_PASS" >> /etc/postfix/sasl_passwd 
chmod 400 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
postalias hash:/etc/aliases
cat /etc/ssl/certs/Equifax_Secure_CA.pem >> /etc/postfix/cacert.pem

/etc/init.d/postfix restart
koha-email-enable koha

sed -i "s@DBHOST@$MYSQL_PORT_3306_TCP_ADDR@g" /etc/koha/sites/koha/koha-conf.xml

DB_PASS=$(awk '/password/ {print $2}' /etc/mysql/koha-db-request.txt)
mysql -h $MYSQL_PORT_3306_TCP_ADDR -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -h $MYSQL_PORT_3306_TCP_ADDR -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "grant all privileges on $DB_NAME.* to '$DB_USER' identified by 
'$DB_PASS';"

sed -i "s@<database>koha_koha</database>@<database>`echo $DB_NAME`</database>@g" /etc/koha/sites/koha/koha-conf.xml
sed -i "s@<user>koha_koha</user>@<user>`echo $DB_USER`</user>@g" /etc/koha/sites/koha/koha-conf.xml
#hopefully remove this next line for koha 3.24
sed -i "s@record->as_xml@record->as_xml_record@g" /usr/share/koha/opac/cgi-bin/opac/oai.pl

service memcached start
service cron start
koha-start-zebra koha
koha-indexer --start koha
koha-enable-sip koha
koha-start-sip koha
koha-plack --enable koha
koha-plack --stop koha
koha-plack --start koha

/usr/sbin/apache2 -DFOREGROUND
/usr/sbin/apache2 -DFOREGROUND


