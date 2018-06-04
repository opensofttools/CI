#!/bin/sh -x

export OPENLDAP_ETC_DIR="/etc/openldap"
export OPENLDAP_RUN_DIR="/run/openldap"
export OPENLDAP_RUN_ARGSFILE="${OPENLDAP_RUN_DIR}/slapd.args"
export OPENLDAP_RUN_PIDFILE="${OPENLDAP_RUN_DIR}/slapd.pid"
export OPENLDAP_MODULES_DIR="/usr/local/openldap-2.4.45/lib"
export OPENLDAP_CONFIG_DIR="${OPENLDAP_ETC_DIR}/conf"
export OPENLDAP_DATA_DIR="${OPENLDAP_ETC_DIR}/data"
export OPENLDAP_ULIMIT="2048"
export OPENLDAP_SSL_KEYS="${OPENLDAP_ETC_DIR}/keys"
export OPENLDAP_LOG_DIR="${OPENLDAP_ETC_DIR}/logs"

export LDAP_BASE=${LDAP_BASE:-"dc=example,dc=org"}
export LDAP_ROOT=${LDAP_ROOT:-"cn=root,${LDAP_BASE}"}
export LDAP_ROOT_PASSWORD=${LDAP_ROOT_PASSWORD:-"123456"}
export LDAP_ROOT_PASSWORD_ENCRYPTED="$(/usr/local/openldap-2.4.45/sbin/slappasswd -u -h '{SSHA}' -s ${LDAP_ROOT_PASSWORD})"
export LDAP_SEARCH_DN=${LDAP_SEARCH_DN:-"cn=search,${LDAP_BASE}"}
export LDAP_SEARCH_PASSWORD=${LDAP_SEARCH_PASSWORD:-"123456"}
export LDAP_SEARCH_ENCRYPTED="$(/usr/local/openldap-2.4.45/sbin/slappasswd -u -h '{SSHA}' -s ${LDAP_SEARCH_PASSWORD})"\

export LDAPTLS_REQCERT=never

#ssl key
certificate_name=ldap

ulimit -n ${OPENLDAP_ULIMIT}

kill_openldap(){
    if [ -f "${OPENLDAP_RUN_DIR}/slapd.pid" ];then
        kill INT $(cat "${OPENLDAP_RUN_DIR}/slapd.pid") &>/dev/null
    fi
}

create_cacert(){
    if [ ! -e "${OPENLDAP_SSL_KEYS}/ca.crt" ];then
        mkdir -p "${OPENLDAP_SSL_KEYS}"
        subject="/C=CN/ST=BeiJing/L=BeiJing/O=admin/OU=admin/CN=admin/emailAddress=admin@example.org"
        openssl req -newkey rsa:2048 -nodes -sha384 -keyout "${OPENLDAP_SSL_KEYS}/ca.key" -x509 -days 36500 -out "${OPENLDAP_SSL_KEYS}/ca.crt" -subj "${subject}"
    fi
    if [ ! -e "${OPENLDAP_SSL_KEYS}/dhparam.pem" ];then
        openssl dhparam -out "${OPENLDAP_SSL_KEYS}/dhparam.pem" 1024
    fi
}

create_certificate(){
    if [ ! -e "${OPENLDAP_SSL_KEYS}/${certificate_name}.key" ];then
        subject="/C=CN/ST=BeiJing/L=BeiJing/O=${certificate_name}/OU=${certificate_name}/CN=${certificate_name}/emailAddress=${certificate_name}@example.org"
        openssl req -newkey rsa:1024 -nodes -sha384 -keyout "${OPENLDAP_SSL_KEYS}/${certificate_name}.key" -out "${OPENLDAP_SSL_KEYS}/${certificate_name}.csr" -subj ${subject}
    fi
    if [ ! -e "${OPENLDAP_SSL_KEYS}/${certificate_name}.cnf" ];then
        cat > "${OPENLDAP_SSL_KEYS}/${certificate_name}.cnf" <<EOF
subjectAltName          = IP:$(hostname -i)
EOF
    fi
    if [ ! -e "${OPENLDAP_SSL_KEYS}/${certificate_name}.crt" ];then
        openssl x509 -req -days 3650 -sha384  -in "${OPENLDAP_SSL_KEYS}/${certificate_name}.csr" -CA "${OPENLDAP_SSL_KEYS}/ca.crt" -CAkey "${OPENLDAP_SSL_KEYS}/ca.key" -CAcreateserial -extfile "${OPENLDAP_SSL_KEYS}/${certificate_name}.cnf" -out "${OPENLDAP_SSL_KEYS}/${certificate_name}.crt"
        openssl x509 -text -noout -in "${OPENLDAP_SSL_KEYS}/${certificate_name}.crt"
    fi
}

replace_conf_file(){
    if [ ! -d "${OPENLDAP_ETC_DIR}/schema" ];then
        mkdir ${OPENLDAP_ETC_DIR} -p
        cp -r /usr/local/openldap-2.4.45/etc/openldap/schema ${OPENLDAP_ETC_DIR}
    fi
    if [ ! -e "${OPENLDAP_BACKEND_DIR}/DB_CONFIG" ];then
        mkdir ${OPENLDAP_DATA_DIR} -p
        cp /usr/local/openldap-2.4.45/var/openldap-data/DB_CONFIG.example ${OPENLDAP_DATA_DIR}/DB_CONFIG
    fi
    if [ ! -e "${OPENLDAP_CONFIG_DIR}/slapd.conf" ];then
        mkdir ${OPENLDAP_CONFIG_DIR} -p
        cp /usr/local/openldap-2.4.45/etc/openldap/slapd.conf ${OPENLDAP_CONFIG_DIR}/
        sed -i "s@cn=root,dc=example,dc=org@${LDAP_ROOT}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
        sed -i "s@cn=search,dc=example,dc=org@${LDAP_SEARCH_DN}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
        sed -i "s@dc=example,dc=org@${LDAP_BASE}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
        sed -i "s@rootpw.*@rootpw ${LDAP_ROOT_PASSWORD_ENCRYPTED}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
    elif [ -e "${OPENLDAP_CONFIG_DIR}/slapd.conf" ];then
        sed -i "s@cn=root,dc=example,dc=org@${LDAP_ROOT}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
        sed -i "s@cn=search,dc=example,dc=org@${LDAP_SEARCH_DN}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
        sed -i "s@dc=example,dc=org@${LDAP_BASE}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
        sed -i "s@rootpw.*@rootpw ${LDAP_ROOT_PASSWORD_ENCRYPTED}@"  ${OPENLDAP_CONFIG_DIR}/slapd.conf
    else
        exit 255
    fi

    /usr/local/openldap-2.4.45/libexec/slapd -f ${OPENLDAP_CONFIG_DIR}/slapd.conf -u root -g root
    result=$?
    echo "${result}" >> ${OPENLDAP_CONFIG_DIR}/run
}

add_user(){
    if [ ! -e ${OPENLDAP_CONFIG_DIR}/base.ldif ];then
        mkdir ${OPENLDAP_CONFIG_DIR} -p
        cp /usr/local/openldap-2.4.45/etc/openldap/base.ldif ${OPENLDAP_CONFIG_DIR}/
        sed -i "s@cn=root,dc=example,dc=org@${LDAP_ROOT}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@cn=search,dc=example,dc=org@${LDAP_SEARCH_DN}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@123456@${LDAP_SEARCH_PASSWORD}@" ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@dc=example,dc=org@${LDAP_BASE}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@SEARCH_userPassword.*@userPassword: ${LDAP_SEARCH_ENCRYPTED}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        /usr/local/openldap-2.4.45/bin/ldapadd -Z -x -H ldap://127.0.0.1:389/ -D "${LDAP_ROOT}" -w ${LDAP_ROOT_PASSWORD}  -f ${OPENLDAP_CONFIG_DIR}/base.ldif
        touch ${OPENLDAP_CONFIG_DIR}/load_base_ldif
    else
        sed -i "s@cn=root,dc=example,dc=org@${LDAP_ROOT}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@cn=search,dc=example,dc=org@${LDAP_SEARCH_DN}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@123456@${LDAP_SEARCH_PASSWORD}@" ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@dc=example,dc=org@${LDAP_BASE}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        sed -i "s@SEARCH_userPassword.*@userPassword: ${LDAP_SEARCH_ENCRYPTED}@"  ${OPENLDAP_CONFIG_DIR}/base.ldif
        /usr/local/openldap-2.4.45/bin/ldapadd -Z -x -H ldap://127.0.0.1:389/ -D "${LDAP_ROOT}" -w ${LDAP_ROOT_PASSWORD}  -f ${OPENLDAP_CONFIG_DIR}/base.ldif
        touch ${OPENLDAP_CONFIG_DIR}/load_base_ldif
    fi
}

run_ldap(){
    /usr/local/openldap-2.4.45/libexec/slapd -f ${OPENLDAP_CONFIG_DIR}/slapd.conf -d -1 -h 'ldap://0.0.0.0:389/ ldaps://0.0.0.0:636/' -u root -g root
}

kill_openldap
create_cacert
create_certificate
replace_conf_file
add_user
kill_openldap
run_ldap

exec "$@"
