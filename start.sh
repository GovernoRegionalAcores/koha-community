#!/bin/bash
sed -i "s@DBHOST@$MYSQL_PORT_3306_TCP_ADDR@g" /etc/koha/sites/koha/koha-conf.xml

DB_PASS=$(awk '/password/ {print $2}' /etc/mysql/koha-db-request.txt)
mysql -h $MYSQL_PORT_3306_TCP_ADDR -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -h $MYSQL_PORT_3306_TCP_ADDR -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "grant all privileges on $DB_NAME.* to '$DB_USER' identified by 
'$DB_PASS';"

sed -i "s@<database>koha_koha</database>@<database>`echo $DB_NAME`</database>@g" /etc/koha/sites/koha/koha-conf.xml
sed -i "s@<user>koha_koha</user>@<user>`echo $DB_USER`</user>@g" /etc/koha/sites/koha/koha-conf.xml

service cron start
koha-start-zebra koha
koha-rebuild-zebra -v -f koha

if [ "$APACHE_USER_UID" != "0" ];then
  usermod -u $APACHE_USER_UID $APACHE_RUN_USER
fi
/usr/sbin/apache2 -DFOREGROUND


