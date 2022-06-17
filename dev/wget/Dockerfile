FROM ubuntu:22.04

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

# CIS-DI-0008 - dockle
RUN chmod g-s usr/bin/wall

WORKDIR /downloads

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        wget=1.21.2-2ubuntu1 \
        ca-certificates=20211016 \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN groupadd -g 1001 nonroot \
    && useradd -u 1001 -g 1001 -d /downloads nonroot \
    && chown -R nonroot:nonroot /downloads

USER nonroot

ENTRYPOINT [ "wget" ]
