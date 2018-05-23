## install openldap in apline 3.7

### openldap baseos

```shell
apk add --upate \
      g++ \
      gcc \
      make \
      libtool \
      openssl \
      openssl-dev \
      unixodbc-dev \
      cyrus-sasl-dev \
      groff
```

#install berkeley-db for openldap

*** pls downloda berkeleydb and OpenLDAP***

[Download berkeleydb](http://download.oracle.com/berkeley-db/db-5.1.29.tar.gz)
[Download OpenLDAP](http://www.openldap.org/)

#### build berkeleydb
```shell
tar xf db-5.1.29.tar.gz -C /root
cd db-5.1.29/build_unix
../dist/configure --prefix=/usr/local/berkeleydb-5.1.29
make && make install
```
### build OpenLDAP
```shell
./configure --prefix=/usr/local/openldap-2.4.45 \
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
      --with-cyrus-sasl

CPPFLAGS=-I/usr/local/berkeleydb-5.1.29/include/ LDFLAGS=-L/usr/local/berkeleydb-5.1.29/lib
export LD_LIBRARY_PATH=/usr/local/berkeleydb-5.1.29/lib
```

### copy db-5.1.29 and openldap
```shell
docker cp $docker_container_name:/usr/local/berkeleydb-5.1.29 $dir
docker cp $docker_container_name:/usr/local/openldap-2.4.45 $dir
```
### run docker build
```shell
docker build -t openldap:2.4.45 .
```
### run docker container
link docker-compose

```
docker-compose -f ldap.yaml up -d
```
