#!/bin/sh

CONFIG_FILE=${CONFIG_FILE:-/var/lib/chrony/chrony.conf}

CHRONYD_ARGS=${CHRONYD_ARGS:-"-d -s -U"}
CHRONY_POOL=${CHRONY_POOL:-"pool.ntp.org"}
CHRONY_CMD_ALLOW=${CHRONY_CMD_ALLOW:-"127.0.0.0/8"}
CHRONY_ALLOW=${CHRONY_ALLOW:-"127.0.0.0/8"}
CHRONY_SYNC_RTC=${CHRONY_SYNC_RTC:-"false"}

rm -f /var/run/chrony/chronyd.pid
chown 100:101 /var/lib/chrony /var/run/chrony
chmod 0750 /var/lib/chrony /var/run/chrony

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "generating config file from environment: ${CONFIG_FILE}"
    cat << EOF > ${CONFIG_FILE}
pool ${CHRONY_POOL} iburst
makestep 0.1 3
local stratum 10
driftfile /var/lib/chrony/chrony.drift
EOF
    if [ "${CHRONY_SYNC_RTC}" = "true" ]; then echo "rtcsync" >> ${CONFIG_FILE}; fi
    if [ "${CHRONY_CMD_ALLOW}" != "" ] ; then
        echo "${CHRONY_CMD_ALLOW}" | tr ',' '\n' | while read CIDR; do echo "cmdallow ${CIDR}" >> ${CONFIG_FILE}; done
    fi
    if [ "${CHRONY_ALLOW}" != "" ] ; then
        echo "${CHRONY_ALLOW}" | tr ',' '\n' | while read CIDR; do echo "allow ${CIDR}" >> ${CONFIG_FILE}; done
    fi
fi

echo "chrony config file (${CONFIG_FILE}):"
cat ${CONFIG_FILE}

echo "starting chrony"
exec /usr/sbin/chronyd ${CHRONYD_ARGS} -f ${CONFIG_FILE}
