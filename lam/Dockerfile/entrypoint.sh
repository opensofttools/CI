#!/bin/sh -x

export ULIMIT="2048"
export NGINX_CONF_DIR="/etc/nginx/conf.d"
export PHP_CONF_CIR="/etc/php7"
export LAM_DIR="/usr/local/lam"
export LAM_RUN_CONF_DIR="/etc/lam/conf"
export LAM_RUN_FILE_DIR="/etc/lam/run"
export LAM_RUN_LOG_DIR="/etc/lam/log"

export LDAP_HOST=${LDAP_HOST:-"ldap://127.0.0.1:389"}
export LDAP_BASE=${LDAP_BASE:-"dc=example,dc=org"}
export LDAP_ROOT=${LDAP_ROOT:-"cn=root,${LDAP_BASE}"}
export LDAP_SEARCH_DN=${LDAP_SEARCH_DN:-"cn=search,${LDAP_BASE}"}
export LDAP_SEARCH_DN_PASSWORD=${LDAP_SEARCH_DN_PASSWORD:-"123456"}

export LAM_RUN_USER="www"
export LAM_RUN_GROUP="www"

add_group(){
    #create group if not exists
    egrep "^${LAM_RUN_GROUP}:" /etc/group >& /dev/null
    if [ $? -ne 0 ];then
        addgroup "${LAM_RUN_GROUP}"
    fi
}

add_user(){
    #create user if not exists
    egrep "^${LAM_RUN_USER}:" /etc/passwd >& /dev/null
    if [ $? -ne 0 ];then
        adduser -D -G "${LAM_RUN_GROUP}" ${LAM_RUN_USER}
    fi
}

create_dir(){
    for dir in "${LAM_RUN_CONF_DIR} ${LAM_RUN_FILE_DIR} ${LAM_RUN_LOG_DIR}";do
        if [ ! -d "${dir}" ];then
            mkdir -pv ${dir}
            chown -R ${LAM_RUN_USER}:${LAM_RUN_GROUP} ${dir}
        fi
    done
}

replace_php_conf(){
    if [ -n "${PHP_CONF_IFLE}" ];then
        ln -sf ${PHP_CONF_IFLE} /etc/php7/php-fpm.conf
        touch "${LAM_RUN_FILE_DIR}/php_replace"
    else
        if [ ! -e "${LAM_RUN_FILE_DIR}/php_replace" ];then
            sed -i "s@user = nobody@user = ${LAM_RUN_USER}@" /etc/php7/php-fpm.conf
            sed -i "s@group = nobody@group = ${LAM_RUN_GROUP}@" /etc/php7/php-fpm.conf
            sed -i "s@;pid = run/php-fpm.pid@pid = run/php7/php-fpm.pid@" /etc/php7/php-fpm.conf
            touch "${LAM_RUN_FILE_DIR}/php_replace"
        fi
    fi
}

replace_nginx_conf(){
    if [ -n "${NGINX_CONF_FILE}" ];then
       ln -sf "${NGINX_CONF_FILE}" "${NGINX_CONF_DIR}/proxy_lam.conf"
    fi
}

#replace lam conf file
replace_lam_conf(){
    if [ ! -e "${LAM_RUN_FILE_DIR}/lam_run" ];then
        if [ ! -e "${LAM_RUN_CONF_DIR}/ldap.conf" ];then
            cp "${LAM_DIR}/etc/ldap.conf" "${LAM_RUN_CONF_DIR}/ldap.conf"
            sed -i "s@ServerURL:.*@ServerURL: ${LDAP_HOST}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            sed -i "s@treesuffix:.*@treesuffix: ${LDAP_BASE}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            sed -i "s@types: suffix_user:.*@types: suffix_user: ou=People,${LDAP_BASE}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            sed -i "s@types: suffix_group:.*@types: suffix_group: ou=People,${LDAP_BASE}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            sed -i "s@loginSearchSuffix:.*@loginSearchSuffix: ${LDAP_BASE}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            sed -i "s@loginSearchDN:.*@loginSearchDN: ${LDAP_SEARCH_DN}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            sed -i "s@loginSearchPassword:.*@loginSearchPassword: ${LDAP_SEARCH_DN_PASSWORD}@" ${LAM_RUN_CONF_DIR}/ldap.conf
            ln -sf "${LAM_RUN_CONF_DIR}/ldap.conf" "${LAM_DIR}/etc/ldap.conf"
        fi
        if [ ! -e "${LAM_RUN_CONF_DIR}/config.cfg" ];then
            cp "${LAM_DIR}/etc/config.cfg" "${LAM_RUN_CONF_DIR}/config.cfg"
            ln -sf "${LAM_RUN_CONF_DIR}/config.cfg" "${LAM_DIR}/etc/config.cfg"
        fi
        touch "${LAM_RUN_FILE_DIR}/lam_run"
    fi
}


run_lam(){
    #change dir ower
    chmod -R 777 /usr/local/lam/sess
    chmod -R 777 /usr/local/lam/tmp
    chown -R ${LAM_RUN_USER}:${LAM_RUN_GROUP} /usr/local/lam
    chown -R ${LAM_RUN_USER}:${LAM_RUN_GROUP} ${LAM_RUN_CONF_DIR}/config.cfg
    chown -R ${LAM_RUN_USER}:${LAM_RUN_GROUP} ${LAM_RUN_CONF_DIR}/ldap.conf
    chmod 777 /etc/lam/conf/*

    # run nginx
    nginx && touch "${LAM_RUN_FILE_DIR}/nginx_run"

    #run php7
    if [ -e "/run/php7/php-fpm.pid" ];then
        pkill php-fpm && php-fpm7 && touch "${LAM_RUN_FILE_DIR}/nginx_run"
    else
        php-fpm7 && touch "${LAM_RUN_FILE_DIR}/php_run"
    fi
    touch ${LAM_RUN_LOG_DIR}/lam.log  && chown -R ${LAM_RUN_USER}:${LAM_RUN_GROUP} ${LAM_RUN_LOG_DIR}/lam.log
    tail -f ${LAM_RUN_LOG_DIR}/lam.log

}

main(){
    add_group
    add_user
    create_dir
    replace_php_conf
    replace_nginx_conf
    replace_lam_conf
    run_lam
}
main "$@"
