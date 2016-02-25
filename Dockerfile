FROM debian:wheezy

ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_PID_FILE  /var/run/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_USER_UID 0

RUN apt-get update && apt-get install -y wget
RUN wget -q -O- http://debian.koha-community.org/koha/gpg.asc | apt-key add -
RUN echo 'deb http://debian.koha-community.org/koha stable main' | tee /etc/apt/sources.list.d/koha.list
RUN apt-get update
RUN apt-get install -y koha-common

RUN cd /etc/koha && sed -i 's@INTRAPORT="80"@INTRAPORT="8080"@g' koha-sites.conf \
    && sed -i 's@DOMAIN=".myDNSname.org"@DOMAIN=""@g' koha-sites.conf

RUN cd /etc/koha && sed -i 's@OPACPORT="80"@OPACPORT="8081"@g' koha-sites.conf

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN a2enmod rewrite
RUN a2enmod cgi
RUN service apache2 restart

RUN cd /etc/mysql \
    && rm koha-common.cnf && cp my.cnf koha-common.cnf

RUN cd /etc/apache2 \
    && echo "Listen 8080" >> ports.conf \
    && echo "Listen 8081" >> ports.conf

ADD koha-common.cnf /etc/mysql/
RUN cd /etc/mysql && koha-create --request-db --marcflavor unimarc koha

RUN koha-translate --install pt-PT
RUN koha-create --populate-db --marcflavor unimarc koha
RUN sed -i "s@Include /etc/koha/apache-shared-disable.conf@# Include /etc/koha/apache-shared-disable.conf@g" /etc/apache2/sites-enabled/koha.conf
RUN koha-enable koha

ENV PERL5LIB  /usr/share/koha/lib/
ENV KOHA_CONF  /etc/koha/sites/koha/koha-conf.xml

COPY start.sh /start.sh
CMD ["/bin/bash", "/start.sh"]
