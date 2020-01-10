#! /bin/sh

set -eu

# Configure slapd based on environment provided config
if [ ! -f slapd.conf ]; then
    cat > slapd.conf << EOF 
##################################################################
# Global configuration options
# For configuration options, see: https://www.openldap.org/doc/admin23/slapdconfig.html
# and for the walk through,  see: http://www.flatmtn.com/article/setting-ldap-back-sql.html
##################################################################

include     /etc/openldap/schema/core.schema
include     /etc/openldap/schema/cosine.schema
include     /etc/openldap/schema/inetorgperson.schema

allow       bind_v2
pidfile     /user/slapd/slapd.pid

threads     ${THREADS_COUNT:-8}

timelimit   ${CONN_TIMEOUT:-1800}
idletimeout ${IDLE_TIMEOUT:-900}
loglevel    ${LOG_LEVEL:-0}
sizelimit   ${RESULT_SIZE_LIMIT:-20}

#################################################################
# Module configuration options
#################################################################

modulepath  /usr/lib/openldap/
moduleload  back_sql.so
moduleload  auditlog.so

#################################################################
# Access control options
# By default, no one can read tables without being authenticated
# Any user authenticated can read.
#################################################################

access to * 
        by anonymous none
        by users     read

##################################################################
# Backend configuration options
# See config details here: https://linux.die.net/man/5/slapd-sql
##################################################################

database    sql

# User definition section

suffix      ${DATABASE_SUFFIX}
dbname      ${DATABASE_NAME}
dbhost      ${DATABASE_HOST}
dbuser      ${DATABASE_USER}
dbpasswd    ${DATABASE_PASSWORD}

readonly    ${DATABASE_RO:-off}
lastmod     ${DATABASE_LAST_MOD:-off}

EOF
else
    >&2 echo "[INFO] Using mounted file found at: $(pwd)/slapd.conf"
fi

# Validating the config created by the user
slaptest -f slapd.conf -d 128 

# Executing the server
slapd -f sladp.conf -u slapd -g slapd