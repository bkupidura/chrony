#!/bin/sh

CONFIG_FILE=/etc/chrony.conf

CHRONYD_ARGS=${CHRONYD_ARGS:-"-d -s"}
CHRONY_POOL=${CHRONY_POOL:-"pool.ntp.org"}
CHRONY_CMD_ALLOW=${CHRONY_CMD_ALLOW:-"127.0.0.0/8"}
CHRONY_ALLOW=${CHRONY_ALLOW:-"127.0.0.0/8"}
CHRONY_SYNC_RTC=${CHRONY_SYNC_RTC:-"false"}

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "generate new config file"
    cat << EOF > ${CONFIG_FILE}
pool ${CHRONY_POOL} iburst
makestep 0.1 3
local stratum 10
driftfile /var/lib/chrony/chrony.drift
EOF
    if [ "${CHRONY_SYNC_RTC}" == "true" ]; then echo "rtcsync" >> ${CONFIG_FILE}; fi
    if [ "${CHRONY_CMD_ALLOW}" != "" ] ; then
        echo "${CHRONY_CMD_ALLOW}" | tr ',' '\n' | while read CIDR; do echo "cmdallow ${CIDR}" >> ${CONFIG_FILE}; done
    fi
    if [ "${CHRONY_ALLOW}" != "" ] ; then
        echo "${CHRONY_ALLOW}" | tr ',' '\n' | while read CIDR; do echo "allow ${CIDR}" >> ${CONFIG_FILE}; done
    fi
fi

echo "chrony config file:"
cat ${CONFIG_FILE}

chown chrony:chrony /var/lib/chrony/chrony.drift

echo "starting chrony"
/usr/sbin/chronyd ${CHRONYD_ARGS} -f ${CONFIG_FILE}
