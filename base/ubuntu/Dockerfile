FROM ubuntu:20.04 as source

# Upgrade to the latest version of Ubuntu.
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /tmp/* /var/lib/apt/lists/*

# CIS-DI-0008 - dockle
RUN chmod g-s usr/bin/* \
    && chmod u-s usr/bin/* \
    && chmod g-s usr/sbin/*

RUN groupadd -g 1001 nonroot \
    && useradd -u 1001 -g 1001 -d /nonroot nonroot \
    && mkdir /nonroot \
    && chown -R nonroot:nonroot /nonroot 
RUN cp /root/.bashrc /nonroot/.bashrc \
    && cp /root/.profile /nonroot/.profile


FROM scratch

COPY --from=source / /

LABEL maintainer="Neeraj Mittal <mittal.neeraj@gmail.com>"

USER nonroot

ENTRYPOINT [ "bash" ]
