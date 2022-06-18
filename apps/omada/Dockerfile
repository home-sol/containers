FROM ghcr.io/home-sol/wget:1.21-2 as downloads

ARG VERSION=5.1.7
ARG OMADA_DIR="Omada_SDN_Controller_v${VERSION}_Linux_x64"
ARG OMADA_TAR="${OMADA_DIR}.tar.gz"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN OMADA_URL=$(wget -q -O - https://www.tp-link.com/us/support/download/omada-software-controller/#Controller_Software | tr '"' '\n' | tr "'" '\n' | grep -e 'tar.gz$' | grep "${VERSION}"); \
    wget -q -O "${OMADA_TAR}" "${OMADA_URL}"

RUN tar zxvf "${OMADA_TAR}" \
    && mv "${OMADA_DIR}" omada \
    && rm -r omada/install.sh omada/uninstall.sh omada/readme.txt omada/release_note.txt


FROM ghcr.io/home-sol/ubuntu:22.04-1

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

# valid values: amd64 (default) | arm64 | armv7l
ARG ARCH=amd64

ENV OMADA_HOME=/opt/tplink/EAPController

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        wget=1.21.2-2ubuntu1 \
        ca-certificates=20211016 \
        openjdk-8-jre-headless=8u312-b07-0ubuntu1 \
        gnupg=2.2.27-3ubuntu2 \
    && rm -rf /tmp/* /var/lib/apt/lists/*

# Install mongodb with lbssl1.1 
# https://www.mongodb.com/community/forums/t/installing-mongodb-over-ubuntu-22-04/159931/3
RUN echo "deb http://security.ubuntu.com/ubuntu impish-security main" | tee /etc/apt/sources.list.d/impish-security.list \
    && wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add - \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends -y \
        libssl1.1=1.1.1l-1ubuntu1.3 \
        mongodb-org-server=5.0.9 \
    && rm -rf /tmp/* /var/lib/apt/lists/*

COPY --from=downloads /nonroot/omada ${OMADA_HOME}


# symlink for mongod
RUN ln -sf "$(which mongod)" "${OMADA_HOME}/bin/mongod"

COPY entrypoint.sh /entrypoint.sh

WORKDIR "${OMADA_HOME}"
RUN mkdir "${OMADA_HOME}/logs" "${OMADA_HOME}/work" \
    && chown -R nonroot:nonroot "${OMADA_HOME}/data" "${OMADA_HOME}/logs" "${OMADA_HOME}/work"

ENV MANAGE_HTTP_PORT=8088
ENV MANAGE_HTTPS_PORT=8043
ENV PORTAL_HTTP_PORT=8088
ENV PORTAL_HTTPS_PORT=8843
ENV SHOW_MONGODB_LOGS=false

ENV SSL_CERTS_DIR=/etc/tplink/certs

USER nonroot
WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814

HEALTHCHECK --interval=1m --timeout=3s --retries=3 \
    CMD "wget --quiet --tries=1 --no-check-certificate -O /dev/null --server-response --timeout=5 'https://localhost:${MANAGE_HTTPS_PORT:-8043}/login' || exit 1"

VOLUME ["/etc/tplink/certs", "/opt/tplink/EAPController/data","/opt/tplink/EAPController/work","/opt/tplink/EAPController/logs"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["java","-server", "-cp","/opt/tplink/EAPController/lib/*::/opt/tplink/EAPController/properties:","com.tplink.smb.omada.starter.OmadaLinuxMain"]
