FROM alpine:latest
LABEL maintainer="Bartosz Kupidura <bartosz.kupidura@gmail.com>"

USER root

RUN apk --update --no-cache add chrony && \
    rm -rf /var/cache/apk/* /etc/chrony /etc/chrony.conf && \
    touch /var/lib/chrony/chrony.drift

HEALTHCHECK --interval=60s --timeout=5s CMD chronyc tracking

EXPOSE 123/udp

COPY scripts/start.sh /start.sh

CMD ["/start.sh"]
