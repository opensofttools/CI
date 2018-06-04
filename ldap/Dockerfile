FROM alpine:3.7

MAINTAINER kirin <kirin_13@163.com>

ENV OPENLDAP_VERSION=2.4.45

VOLUME ["/etc/openldap/"]

#download openldap and berkeleydb
RUN wget http://download.oracle.com/berkeley-db/db-5.1.29.tar.gz -P /tmp \
  && wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.45.tgz -P /tmp

RUN set -x \
  && mkdir -vp \
    /run/openldap \
    /etc/openldap \
    /etc/openldap/conf \
    /etc/openldap/data \
    /etc/openldap/logs \
    /etc/openldap/run \
  && apk update \
  && apk add \
    libtool \
    openssl \
    openssl-dev \
    unixodbc-dev \
    cyrus-sasl-dev \
    groff \
    g++ \
    gcc \
    make \
    cyrus-sasl-dev \
    perl-dev

#build berkeleydb
RUN tar zxf /tmp/db-5.1.29.tar.gz -C /tmp \
  && cd /tmp/db-5.1.29/build_unix \
  && ../dist/configure --prefix=/usr/local/berkeleydb-5.1.29 \
  && make \
  && make install

#build openldap
RUN tar zxf /tmp/openldap-2.4.45.tgz -C /tmp \
  && cd /tmp/openldap-2.4.45 \
  && export CPPFLAGS=-I/usr/local/berkeleydb-5.1.29/include/ \
  && export LDFLAGS=-L/usr/local/berkeleydb-5.1.29/lib \
  && export LD_LIBRARY_PATH=/usr/local/berkeleydb-5.1.29/lib \
  && ./configure --prefix=/usr/local/openldap-2.4.45 \
        --datadir=/usr/local/openldap-2.4.45/openldap-data \
        --mandir=/usr/local/openldap-2.4.45/man \
        --with-odbc=auto \
        --enable-debug \
        --enable-syslog \
        --enable-crypt \
        --enable-dynamic \
        --enable-modules \
        --enable-local \
        --enable-slapd \
        --enable-spasswd \
        --enable-bdb=mod \
        --enable-hdb=mod \
        --enable-dnssrv=mod \
        --enable-ldap=mod \
        --enable-meta=mod \
        --enable-monitor=mod \
        --enable-null=mod \
        --enable-passwd=mod \
        --enable-relay=mod \
        --enable-shell=mod \
        --enable-sock=mod \
        --enable-sql=yes \
        --enable-overlays=mod \
        --enable-dnssrv=mod \
        --enable-overlays=mod \
        --enable-accesslog=mod \
        --enable-auditlog=mod \
        --enable-ppolicy=mod \
        --enable-perl=mod \
        --with-tls=openssl \
        --with-cyrus-sasl \
  && make depend \
  && make \
  && make install

RUN rm -vfr /var/cache/apk/* \
  && rm -rf /tmp/*

#fix read README.md "build berkeleydb" and "build openldap"
COPY conf/base.ldif /usr/local/openldap-2.4.45/etc/openldap/
COPY conf/ldap.conf /usr/local/openldap-2.4.45/etc/openldap/
COPY conf/slapd.conf /usr/local/openldap-2.4.45/etc/openldap/
COPY conf/entrypoint.sh /usr/local/bin/

EXPOSE 389 636

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
