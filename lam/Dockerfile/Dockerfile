FROM alpine:3.10 AS builder

RUN set -x \
 && apk add --update \
  	perl \
    make \
    bash \
  && cd /tmp \
  && wget https://jaist.dl.sourceforge.net/project/lam/LAM/6.3/ldap-account-manager-6.3.tar.bz2 \
  && tar xf ldap-account-manager-6.3.tar.bz2 -C /tmp \
  && cd /tmp/ldap-account-manager-6.3 \
  && ./configure \
    --with-httpd-user=root \
    --prefix=/usr/local/lam \
    --with-httpd-group=root \
  && make install 


FROM alpine:3.10

MAINTAINER kirin <kirin_13@163.com>

COPY --from=builder /usr/local/lam /usr/local/lam

RUN set -x \
 && addgroup www \
 && adduser -D -G www www \
 && mkdir -vp \
    /run/nginx \
    /run/php7 \
 && apk add --update \
  	nginx \
  	php7-fpm \
  	php7-mcrypt \
  	php7-soap \
  	php7-openssl \
  	php7-zip \
  	php7-xmlrpc \
  	php7-ldap \
  	php7-xmlreader \
  	php7-json \
  	php7-gettext \
        php7-session \
  	perl \
  && rm -rf /etc/nginx/conf.d/default.conf \
  && rm -vfr /var/cache/apk/* \
  && chown -R www:www /usr/local/lam \
  && cp /usr/local/lam/etc/unix.conf.sample /usr/local/lam/etc/ldap.conf

COPY config.cfg /usr/local/lam/etc
COPY ldap.conf /usr/local/lam/etc
ADD proxy_lam.conf /etc/nginx/conf.d/
ADD entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
