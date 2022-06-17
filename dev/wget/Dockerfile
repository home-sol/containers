FROM ubuntu:22.04

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        wget=1.21.2-2ubuntu1 \
        ca-certificates=20211016 \
    && rm -rf /tmp/* /var/lib/apt/lists/*

ENTRYPOINT [ "wget" ]
