FROM debian:11.3-slim

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

RUN echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        wget=1.21-1+deb11u1 \
        ca-certificates=20210119 \
    && rm -rf /tmp/* /var/lib/apt/lists/*

ENTRYPOINT [ "wget" ]
