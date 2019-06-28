FROM alpine:3.10 AS builder

ENV OPENLDAP_VERSION=2.4.47 DB_VERSION=5.1.29

RUN set -x \
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
    perl-dev

#download openldap and berkeleydb
RUN wget http://download.oracle.com/berkeley-db/db-${DB_VERSION}.tar.gz -P /tmp \
  && wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-${OPENLDAP_VERSION}.tgz -P /tmp

#build berkeleydb
RUN tar zxf /tmp/db-${DB_VERSION}.tar.gz -C /tmp \
  && cd /tmp/db-${DB_VERSION}/build_unix \
  && ../dist/configure --prefix=/usr/local/berkeleydb-${DB_VERSION} \
  && make \
  && make install

#build openldap
RUN tar zxf /tmp/openldap-${OPENLDAP_VERSION}.tgz -C /tmp \
  && cd /tmp/openldap-${OPENLDAP_VERSION} \
  && export CPPFLAGS=-I/usr/local/berkeleydb-${DB_VERSION}/include/ \
  && export LDFLAGS=-L/usr/local/berkeleydb-${DB_VERSION}/lib \
  && export LD_LIBRARY_PATH=/usr/local/berkeleydb-${DB_VERSION}/lib \
  && ./configure --prefix=/usr/local/openldap-${OPENLDAP_VERSION} \
        --datadir=/usr/local/openldap-${OPENLDAP_VERSION}/openldap-data \
        --mandir=/usr/local/openldap-${OPENLDAP_VERSION}/man \
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


FROM alpine:3.10

MAINTAINER kirin <kirin_13@163.com>

ENV OPENLDAP_VERSION=2.4.47 DB_VERSION=5.1.29

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
    unixodbc-dev \
    cyrus-sasl-dev \
  && rm -vfr /var/cache/apk/* \
  && rm -rf /tmp/*

COPY --from=builder /usr/local/berkeleydb-${DB_VERSION} /usr/local/berkeleydb-${DB_VERSION}
COPY --from=builder /usr/local/openldap-${OPENLDAP_VERSION} /usr/local/openldap-${OPENLDAP_VERSION}
#fix read README.md "build berkeleydb" and "build openldap"
COPY conf/* /usr/local/openldap-${OPENLDAP_VERSION}/etc/openldap/
#COPY conf/base.ldif /usr/local/openldap-${OPENLDAP_VERSION}/etc/openldap/
#COPY conf/ldap.conf /usr/local/openldap-${OPENLDAP_VERSION}/etc/openldap/
#COPY conf/slapd.conf /usr/local/openldap-${OPENLDAP_VERSION}/etc/openldap/
COPY conf/entrypoint.sh /usr/local/bin/

EXPOSE 389 636

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


VOLUME ["/etc/openldap/"]
