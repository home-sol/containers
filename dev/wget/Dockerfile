FROM debian:11.3

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        wget ca-certificates\
    && rm -rf /tmp/* /var/lib/apt/lists/*

ENTRYPOINT [ "wget" ]
