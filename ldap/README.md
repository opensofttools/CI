## install openldap in apline 3.7

### run docker build
```shell
docker build -t openldap:2.4.45 .
```
### run docker container
link docker-compose

```
docker-compose -f ldap.yaml up -d
```
