FROM alpine:3.7

MAINTAINER kirin <kirin_13@163.com>

ENV OPENLDAP_VERSION=2.4.45

VOLUME ["/etc/openldap/"]

RUN set -x \
  && mkdir -vp \
    /run/openldap \
    /etc/openldap \
    /etc/openldap/conf \
    /etc/openldap/data \
    /etc/openldap/logs \
    /etc/openldap/run \
  && echo "http://mirrors.aliyun.com/alpine/v3.7/main/" > /etc/apk/repositories \
  && apk add --update \
    libtool \
    openssl \
    openssl-dev \
    unixodbc-dev \
    cyrus-sasl-dev \
    groff \
  && rm -vfr /var/cache/apk/*

#fix read README.md "build berkeleydb" and "build openldap"
ADD berkeleydb-5.1.29.tar.gz /usr/local/
ADD openldap-2.4.45.tar.gz /usr/local/
COPY entrypoint.sh /usr/local/bin/

EXPOSE 389 636

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
