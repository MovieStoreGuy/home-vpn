#! /bin/sh

set -eu

# Configure slapd based on environment provided config
if [ ! -f slapd.conf ]; then
    cat | tee -a slapd.conf << EOF 
# For configuration options, see: https://www.openldap.org/doc/admin23/slapdconfig.html
# Global configuration settings
timelimit   ${CONN_TIMEOUT:-1800}
idletimeout ${IDLE_TIMEOUT:-900}
loglevel    ${LOG_LEVEL:-0}
sizelimit   ${RESULT_SIZE_LIMIT:-20}

# Root domain config settings
rootdn      ${LDAP_ROOT_DOMAIN}
rootpw      ${LDAP_ROOT_PASSWORD}

# Backend configuration
# See config details here: https://linux.die.net/man/5/slapd-sql
backend     sql
database    sql
readonly    ${DATABASE_RO:-off}
dbname      ${DATABASE_NAME}
dbhost      ${DATABASE_HOST}
dbuser      ${DATABASE_USER}
dbpasswd    ${DATABASE_PASSWORD}
EOF
else
    >&2 echo "[INFO] Using mounted file found at: $(pwd)/slapd.conf"
fi

slapd -f sladp.conf -u slapd -g slapd