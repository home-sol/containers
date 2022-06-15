ARG BASE=openjdk:8u332-jre-bullseye

FROM ghcr.io/home-sol/wget:1.21-1 as downloads

ARG VERSION=5.1.7
ARG OMADA_DIR="Omada_SDN_Controller_v${VERSION}_Linux_x64"
ARG OMADA_TAR="${OMADA_DIR}.tar.gz"

WORKDIR /downloads
RUN OMADA_URL=$(wget -q -O - https://www.tp-link.com/us/support/download/omada-software-controller/#Controller_Software | tr '"' '\n' | tr "'" '\n' | grep -e 'tar.gz$' | grep "${VERSION}"); \
    wget -q -O ${OMADA_TAR} ${OMADA_URL}

RUN tar zxvf ${OMADA_TAR} \
    && mv ${OMADA_DIR} omada \
    && rm -r omada/install.sh omada/uninstall.sh omada/readme.txt omada/release_note.txt


FROM ghcr.io/home-sol/wget:1.21-1 as download-mongodb-key

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        gpg \
    && rm -rf /tmp/* /var/lib/apt/lists/*


RUN wget -q https://www.mongodb.org/static/pgp/server-5.0.asc
RUN cat server-5.0.asc | gpg --dearmor  > server-5.0.gpg \
    && rm server-5.0.asc \
    && install server-5.0.gpg /etc/apt/trusted.gpg.d/


FROM ${BASE}


LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

# valid values: amd64 (default) | arm64 | armv7l
ARG ARCH=amd64

ENV OMADA_DIR=/opt/tplink/EAPController

COPY --from=download-mongodb-key /etc/apt/trusted.gpg.d/server-5.0.gpg /etc/apt/trusted.gpg.d/
RUN echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        procps=2:3.3.17-5 \
        mongodb-org-database=5.0.9 \
    && rm -rf /tmp/* /var/lib/apt/lists/*


COPY --from=downloads /downloads/omada ${OMADA_DIR}


# symlink for mongod
RUN ln -sf "$(which mongod)" "${OMADA_DIR}/bin/mongod"

COPY entrypoint.sh /entrypoint.sh

ENV MANAGE_HTTP_PORT=8088
ENV MANAGE_HTTPS_PORT=8043
ENV PORTAL_HTTP_PORT=8088
ENV PORTAL_HTTPS_PORT=8843
ENV SHOW_MONGODB_LOGS=false

ENV KEYSTORE_DIR=${OMADA_DIR}/data/keystore

ENV SSL_CERTS_DIR=/etc/tplink/certs

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814
VOLUME ["/etc/tplink/certs", "/opt/tplink/EAPController/data","/opt/tplink/EAPController/work","/opt/tplink/EAPController/logs"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["java","-server", "-cp","/opt/tplink/EAPController/lib/*::/opt/tplink/EAPController/properties:","com.tplink.smb.omada.starter.OmadaLinuxMain"]
