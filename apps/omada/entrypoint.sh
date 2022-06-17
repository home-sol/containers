#!/usr/bin/env bash

set -e

SSL_CERTS_DIR="${SSL_CERT_NAME:-/cert/tls.crt}"
SSL_CERT_KEY="${SSL_KEY_NAME:-/cert/tls.key}"

KEYSTORE_DIR="${OMADA_HOME}/data/keystore"

set_port_property() {
    echo "INFO: Setting '${1}' to ${3} in omada.properties"
    sed -i "s/^${1}=${2}$/${1}=${3}/g" /opt/tplink/EAPController/properties/omada.properties
}

set_port_property "manage.http.port" 8088 "${MANAGE_HTTP_PORT}"
set_port_property "manage.https.port" 8043 "${MANAGE_HTTPS_PORT}"
set_port_property "portal.http.port" 8088 "${PORTAL_HTTP_PORT}"
set_port_property "portal.https.port" 8843 "${PORTAL_HTTPS_PORT}"

# make sure permissions are set appropriately on each directory
for DIR in data work logs; do
    OWNER="$(stat -c '%u' /opt/tplink/EAPController/${DIR})"
    GROUP="$(stat -c '%g' /opt/tplink/EAPController/${DIR})"

    if [ "${OWNER}" != "508" ] || [ "${GROUP}" != "508" ]; then
        # notify user that uid:gid are not correct and fix them
        echo "WARNING: owner or group (${OWNER}:${GROUP}) not set correctly on '/opt/tplink/EAPController/${DIR}'"
        echo "INFO: setting correct permissions"
        chown -R omada:omada "/opt/tplink/EAPController/${DIR}"
    fi
done

# check to see if there is a db directory; create it if it is missing
if [ ! -d "/opt/tplink/EAPController/data/db" ]; then
    echo "INFO: Database directory missing; creating '/opt/tplink/EAPController/data/db'"
    mkdir /opt/tplink/EAPController/data/db
    chown omada:omada /opt/tplink/EAPController/data/db
    echo "done"
fi

# check to see if there is a work directory; create it if it is missing
if [ ! -d "/opt/tplink/EAPController/work" ]; then
    echo "INFO: Work directory missing; creating '/opt/tplink/EAPController/wrk'"
    mkdir /opt/tplink/EAPController/work
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
    chown omada:omada "${KEYSTORE_DIR}/eap.keystore"
    chmod 400 "${KEYSTORE_DIR}/eap.keystore"
fi

tail -F -n 0 /opt/tplink/EAPController/logs/server.log &

# tail the mongodb logs if set to true
if [ "${SHOW_MONGODB_LOGS}" = "true" ]; then
    tail -F -n 0 -q /opt/tplink/EAPController/logs/mongod.log &
fi

# run the actual command
exec "${@}"
