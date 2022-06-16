FROM ghcr.io/home-sol/wget:1.21-1 as downloads

ARG VERSION=5.1.7
ARG OMADA_DIR="Omada_SDN_Controller_v${VERSION}_Linux_x64"
ARG OMADA_TAR="${OMADA_DIR}.tar.gz"

WORKDIR /downloads

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN OMADA_URL=$(wget -q -O - https://www.tp-link.com/us/support/download/omada-software-controller/#Controller_Software | tr '"' '\n' | tr "'" '\n' | grep -e 'tar.gz$' | grep "${VERSION}"); \
    wget -q -O "${OMADA_TAR}" "${OMADA_URL}"

RUN tar zxvf "${OMADA_TAR}" \
    && mv "${OMADA_DIR}" omada \
    && rm -r omada/install.sh omada/uninstall.sh omada/readme.txt omada/release_note.txt


FROM ubuntu:20.04

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

# valid values: amd64 (default) | arm64 | armv7l
ARG ARCH=amd64

ENV OMADA_HOME=/opt/tplink/EAPController

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        openjdk-8-jre-headless=8u312-b07-0ubuntu1~20.04 \
        mongodb-server-core=1:3.6.9+really3.6.8+90~g8e540c0b6d-0ubuntu5.3 \
    && rm -rf /tmp/* /var/lib/apt/lists/*

COPY --from=downloads /downloads/omada ${OMADA_HOME}


# symlink for mongod
RUN ln -sf "$(which mongod)" "${OMADA_HOME}/bin/mongod"

COPY entrypoint.sh /entrypoint.sh

RUN groupadd -g 508 omada \
    && useradd -u 508 -g 508 -d "${OMADA_HOME}" omada \
    && mkdir "${OMADA_HOME}/logs" "${OMADA_HOME}/work" \
    && chown -R omada:omada "${OMADA_HOME}/data" "${OMADA_HOME}/logs" "${OMADA_HOME}/work"

USER omada

ENV MANAGE_HTTP_PORT=8088
ENV MANAGE_HTTPS_PORT=8043
ENV PORTAL_HTTP_PORT=8088
ENV PORTAL_HTTPS_PORT=8843
ENV SHOW_MONGODB_LOGS=false

ENV KEYSTORE_DIR=${OMADA_HOME}/data/keystore

ENV SSL_CERTS_DIR=/etc/tplink/certs

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814
VOLUME ["/etc/tplink/certs", "/opt/tplink/EAPController/data","/opt/tplink/EAPController/work","/opt/tplink/EAPController/logs"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["java","-server", "-cp","/opt/tplink/EAPController/lib/*::/opt/tplink/EAPController/properties:","com.tplink.smb.omada.starter.OmadaLinuxMain"]
