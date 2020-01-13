#! /bin/sh

set -eu

# ODBC file instructions

if [ ! -f /usr/local/lib/etc/odbc.ini ]; then
    cat > /usr/local/lib/etc/odbc.ini << EOF
;
;  odbc.ini
;
[ODBC Data Sources]
PgSQL=PostgreSQL

[Users]
Driver=/usr/lib/psqlodbcw.so
Description=Connection to LDAP/POSTGRESQL
Servername=${DATABASE_HOST}
Port=${DATABASE_PORT}
Protocol=6.4
FetchBufferSize=99
Username=${DATABASE_USER}
Password=${DATABASE_PASSWORD}
Database=Users
ReadOnly=no
Debug=1
CommLog=1

[ODBC]
InstallDir=/usr/lib
EOF
else 
    >&2 echo "[INFO] Using Using mounted file found at: /usr/local/lib/etc/odbc.ini"
fi

if [ ! -f /usr/local/lib/etc/odbcinst.ini ]; then
    cat > /usr/local/lib/etc/odbcinst.ini << EOF
;
;  odbcinst.ini
;
[Users]
Description=ODBC for PostgreSQL
Driver=/usr/lib/psqlodbcw.so

[ODBC]
Trace=1
Debug=1
Pooling=No
EOF
else 
    >&2 echo "[INFO] Using Using mounted file found at: /usr/local/lib/etc/odbcinst.ini"
fi


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
dbname      Users
dbhost      ${DATABASE_HOST}
dbuser      ${DATABASE_USER}
dbpasswd    ${DATABASE_PASSWORD}

readonly    ${DATABASE_RO:-off}
lastmod     ${DATABASE_LAST_MOD:-off}

EOF
    [ $? -eq 0 ] && >&2 echo "[INFO] Successfully written slapd.conf" || exit 1
else
    >&2 echo "[INFO] Using mounted file found at: $(pwd)/slapd.conf"
fi

# Validating the config created by the user
slaptest -f slapd.conf -d 128 

# Executing the server
slapd -f sladp.conf -u slapd -g slapd