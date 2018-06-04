FROM alpine:3.7

MAINTAINER kirin <kirin_13@163.com>

ENV NGINX_VERSION=1.12
ENV PHP_VERSION=5.6.35
ENV LAM=6.3

VOLUME ["/etc/lam/"]

RUN set -x \
 && addgroup www \
 && adduser -D -G www www \
 && mkdir -vp \
    /run/nginx \
    /run/php5 \
 && apk add --update \
  	nginx \
  	php5-fpm \
  	php5-mcrypt \
  	php5-soap \
  	php5-openssl \
  	php5-zip \
  	php5-xmlrpc \
  	php5-ldap \
  	php5-xmlreader \
  	php5-json \
  	php5-gettext \
  	perl \
    make \
    bash \
  && cd /tmp \
  && rm -rf /etc/nginx/conf.d/default.conf \
  && wget https://jaist.dl.sourceforge.net/project/lam/LAM/6.3/ldap-account-manager-6.3.tar.bz2 \
  && tar xf ldap-account-manager-6.3.tar.bz2 -C /tmp \
  && cd /tmp/ldap-account-manager-6.3 \
  && ./configure \
    --with-httpd-user=root \
    --prefix=/usr/local/lam \
    --with-httpd-group=root \
  && make install \
  && rm -rf /tmp/ldap-account-manager-6.3 \
  && rm -rf /tmp/ldap-account-manager-6.3.tar.bz2 \
  && rm -rf /etc/nginx/conf.d/default.conf \
  && rm -vfr /var/cache/apk/* \
  && chown -R www:www /usr/local/lam \
  && cp /usr/local/lam/etc/unix.conf.sample /usr/local/lam/etc/ldap.conf

COPY config.cfg /usr/local/lam/etc
COPY ldap.conf /usr/local/lam/etc
ADD proxy_lam.conf /etc/nginx/conf.d/
ADD entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
