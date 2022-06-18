#!/usr/bin/env bash

set -e

SSL_CERTS_DIR="${SSL_CERT_NAME:-/cert/tls.crt}"
SSL_CERT_KEY="${SSL_KEY_NAME:-/cert/tls.key}"

KEYSTORE_DIR="${OMADA_HOME}/data/keystore"

set_port_property() {
    echo "INFO: Setting '${1}' to ${3} in omada.properties"
    sed -i "s/^${1}=${2}$/${1}=${3}/g" ${OMADA_HOME}/properties/omada.properties
}

set_port_property "manage.http.port" 8088 "${MANAGE_HTTP_PORT}"
set_port_property "manage.https.port" 8043 "${MANAGE_HTTPS_PORT}"
set_port_property "portal.http.port" 8088 "${PORTAL_HTTP_PORT}"
set_port_property "portal.https.port" 8843 "${PORTAL_HTTPS_PORT}"

# make sure permissions are set appropriately on each directory
for DIR in data work logs; do
    OWNER="$(stat -c '%u' ${OMADA_HOME}/${DIR})"
    GROUP="$(stat -c '%g' ${OMADA_HOME}/${DIR})"

    if [ "${OWNER}" != "1001" ] || [ "${GROUP}" != "1001" ]; then
        # notify user that uid:gid are not correct and fix them
        echo "WARNING: owner or group (${OWNER}:${GROUP}) not set correctly on '/opt/tplink/EAPController/${DIR}'"
        echo "INFO: setting correct permissions"
        chown -R nonroot:nonroot "/opt/tplink/EAPController/${DIR}"
    fi
done

# check to see if there is a db directory; create it if it is missing
if [ ! -d "${OMADA_HOME}/data/db" ]; then
    echo "INFO: Database directory missing; creating '${OMADA_HOME}/data/db'"
    mkdir ${OMADA_HOME}/data/db
    chown nonroot:nonroot ${OMADA_HOME}/data/db
    echo "done"
fi

# check to see if there is a work directory; create it if it is missing
if [ ! -d "${OMADA_HOME}/work" ]; then
    echo "INFO: Work directory missing; creating '${OMADA_HOME}/wrk'"
    mkdir ${OMADA_HOME}/work
    echo "done"
fi

# Import a cert from a possibly mounted secret or file at /cert
if [ -f "${SSL_CERTS_DIR}/tls.crt" ] && [ -f "${SSL_CERTS_DIR}/tls.key" ]; then
    # check to see if the KEYSTORE_DIR exists (it won't on upgrade)
    if [ ! -d "${KEYSTORE_DIR}" ]; then
        echo "INFO: creating keystore directory (${KEYSTORE_DIR})"
        mkdir "${KEYSTORE_DIR}"
    fi

    echo "INFO: Importing cert from ${SSL_CERTS_DIR}"
    # delete the existing keystore
    rm -f "${KEYSTORE_DIR}/eap.keystore"

    # example certbot usage: ./certbot-auto certonly --standalone --preferred-challenges http -d mydomain.net
    openssl pkcs12 -export \
        -inkey "${SSL_CERTS_DIR}/tls.key" \
        -in "${SSL_CERTS_DIR}/tls.crt" \
        -certfile "${SSL_CERTS_DIR}/tls.crt" \
        -name eap \
        -out "${KEYSTORE_DIR}/eap.keystore" \
        -passout pass:tplink

    # set ownership/permission on keystore
    chown nonroot:nonroot "${KEYSTORE_DIR}/eap.keystore"
    chmod 400 "${KEYSTORE_DIR}/eap.keystore"
fi

tail -F -n 0 ${OMADA_HOME}/logs/server.log &

# tail the mongodb logs if set to true
if [ "${SHOW_MONGODB_LOGS}" = "true" ]; then
    tail -F -n 0 -q ${OMADA_HOME}/logs/mongod.log &
fi

# run the actual command
exec "${@}"
