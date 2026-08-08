![Docker Image CI](https://github.com/bkupidura/chrony/actions/workflows/docker-image.yml/badge.svg)

# docker container with chrony

chrony is a versatile implementation of the Network Time Protocol (NTP). It can synchronise the system clock with NTP servers, reference clocks (e.g. GPS receiver), and manual input using wristwatch and keyboard. It can also operate as an NTPv4 (RFC 5905) server and peer to provide a time service to other computers in the network.

## Usage

### Docker

```
docker run --name chrony --rm \
  --cap-drop ALL --cap-add SYS_TIME --cap-add NET_BIND_SERVICE --cap-add FOWNER --cap-add CHOWN \
  -d -p 123:123/udp \
  -e CHRONY_POOL="0.pl.pool.ntp.org" -e CHRONY_SYNC_RTC="true" \
  ghcr.io/bkupidura/chrony:latest
```

The container always runs as the non-root `chrony` user (uid 100/gid 101).
`CAP_NET_BIND_SERVICE` is required to bind UDP/123 as non-root, `CAP_SYS_TIME`
to adjust the system clock, `CAP_FOWNER`/`CAP_CHOWN` for start.sh to fix up
ownership/permissions on `/var/lib/chrony` and `/var/run/chrony` itself.

For a read-only root filesystem, mount `/var/lib/chrony` and `/var/run/chrony`
as writable and owned by uid 100/gid 101, e.g.:

```
docker run --name chrony --rm --read-only \
  --cap-drop ALL --cap-add SYS_TIME --cap-add NET_BIND_SERVICE --cap-add FOWNER --cap-add CHOWN \
  --tmpfs /var/lib/chrony:uid=100,gid=101,mode=0750 \
  --tmpfs /var/run/chrony:uid=100,gid=101,mode=0750 \
  -d -p 123:123/udp \
  -e CHRONY_POOL="0.pl.pool.ntp.org" -e CHRONY_SYNC_RTC="true" \
  ghcr.io/bkupidura/chrony:latest
```

### K8s

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: home-infra

---
apiVersion: v1
kind: Service
metadata:
  name: chrony
  namespace: home-infra
  labels:
    app.kubernetes.io/name: chrony
spec:
  type: LoadBalancer
  publishNotReadyAddresses: false
  ports:
    - name: chrony
      port: 123
      protocol: UDP
  selector:
    app.kubernetes.io/name: chrony

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: chrony
  namespace: home-infra
  labels:
    app.kubernetes.io/name: chrony
spec:
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app.kubernetes.io/name: chrony
  template:
    metadata:
      labels:
        app.kubernetes.io/name: chrony
    spec:
      securityContext:
        fsGroup: 101
      containers:
        - name: chrony
          image: ghcr.io/bkupidura/chrony:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: chrony
              containerPort: 123
              protocol: UDP
          env:
            - name: TZ
              value: Europe/Warsaw
            - name: CHRONY_POOL
              value: 0.pl.pool.ntp.org
            - name: CHRONY_SYNC_RTC
              value: "true"
          securityContext:
            runAsNonRoot: true
            runAsUser: 100
            runAsGroup: 101
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
              add: ["SYS_TIME", "NET_BIND_SERVICE", "FOWNER", "CHOWN"]
          volumeMounts:
            - name: tz-config
              mountPath: /etc/localtime
              readOnly: true
            - name: tzdata-config
              mountPath: /etc/timezone
              readOnly: true
            - name: chrony-lib
              mountPath: /var/lib/chrony
            - name: chrony-run
              mountPath: /var/run/chrony
          readinessProbe:
            exec:
              command:
                - chronyc
                - tracking
            initialDelaySeconds: 30
            periodSeconds: 60
            timeoutSeconds: 5
          livenessProbe:
            exec:
              command:
              - chronyc
              - tracking
            initialDelaySeconds: 30
            periodSeconds: 60
            timeoutSeconds: 5
      volumes:
        - name: tz-config
          hostPath:
            path: /etc/localtime
        - name: tzdata-config
          hostPath:
            path: /etc/timezone
        - name: chrony-lib
          emptyDir: {}
        - name: chrony-run
          emptyDir: {}
```

## Env variable

* CHRONYD_ARGS - `chronyd` arguments (default: `-d -s -U`)
* CONFIG_FILE - path to the chrony config file; if it already exists it's used as-is and all CHRONY_* env vars below are ignored, otherwise it's generated from them (default: `/var/lib/chrony/chrony.conf`)
* CHRONY_POOL - ntp pool address (default: `pool.ntp.org`)
* CHRONY_CMD_ALLOW - allow cmd (`cmdallow`) CIDRs, comma separated list (default: `127.0.0.0/8`)
* CHRONY_ALLOW - allow (`allow`) CIDRs, comma separated list (default: `127.0.0.0/8`)
* CHRONY_SYNC_RTC - enable syncing local clock (`rtcsync`) (default: `false`)
