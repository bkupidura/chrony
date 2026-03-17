FROM alpine:latest
LABEL maintainer="Bartosz Kupidura <bartosz@spof.pl>"

USER root

RUN apk --update --no-cache add chrony && \
    rm -rf /var/cache/apk/* /etc/chrony /etc/chrony.conf && \
    mkdir /var/run/chrony && \
    touch /var/lib/chrony/chrony.drift

HEALTHCHECK --interval=60s --timeout=5s CMD chronyc tracking

EXPOSE 123/udp

COPY scripts/start.sh /start.sh

CMD ["/start.sh"]
