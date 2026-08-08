FROM alpine:latest
LABEL maintainer="Bartosz Kupidura <bartosz@spof.pl>"

USER root

RUN apk --update --no-cache add chrony libcap && \
    rm -rf /var/cache/apk/* /etc/chrony /etc/chrony.conf && \
    mkdir /var/run/chrony && \
    chown chrony:chrony /var/run/chrony && \
    chmod 0750 /var/run/chrony

HEALTHCHECK --interval=60s --timeout=5s CMD chronyc tracking

EXPOSE 123/udp

COPY scripts/start.sh /start.sh

RUN setcap 'cap_sys_time,cap_net_bind_service=+ep' /usr/sbin/chronyd && \
    setcap 'cap_sys_time,cap_net_bind_service,cap_fowner,cap_chown=+ep' /bin/busybox

USER chrony

CMD ["/start.sh"]
