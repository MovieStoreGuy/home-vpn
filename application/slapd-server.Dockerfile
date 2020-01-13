FROM alpine:3.9 AS slapd-server

# Installing OpenLDAP and the backend requirements
# this is to allow it to communicate with an SQL based backend instead of the default
RUN set -x && \
    apk add --no-cache \
        openldap \
        openldap-back-sql \
        psqlodbc \
        openldap-overlay-auditlog \
        dumb-init && \
    addgroup -S slapd && \
    adduser  -S slapd -G slapd && \
    mkdir -p /user/slapd && \
    touch /user/slapd/odbc.ini /user/slapd/odbcinst.ini && \
    ln -sf /etc/odbc.ini /user/odbc.ini && \
    chown -R slapd:slapd /user/slapd && \
    set +x

WORKDIR /user/slapd
COPY ./slapd-runner.sh /bin/slapd-runner.sh

# Port configuration settings can be found here:
# https://www.openldap.org/doc/admin24/runningslapd.html
EXPOSE 389 636
USER slapd:slapd

ENTRYPOINT ["dumb-init", "--"]
CMD ["slapd-runner.sh"]