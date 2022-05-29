# docker container with chrony
chrony is a versatile implementation of the Network Time Protocol (NTP). It can synchronise the system clock with NTP servers, reference clocks (e.g. GPS receiver), and manual input using wristwatch and keyboard. It can also operate as an NTPv4 (RFC 5905) server and peer to provide a time service to other computers in the network.

## Usage
### Docker
```
  docker run --name chrony --rm --cap-add SYS_TIME -d -p 123:123/udp -e CHRONY_POOL="0.pl.pool.ntp.org" -e CHRONY_SYNC_RTC="true" bkupidura/chront:latest
```
### K8s
```
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
  loadBalancerIP: "192.168.0.100"
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
      containers:
        - name: chrony
          image: bkupidura/chrony:latest
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
            capabilities:
              add: ["SYS_TIME"]
          volumeMounts:
            - name: tz-config
              mountPath: /etc/localtime
              readOnly: true
            - name: tzdata-config
              mountPath: /etc/timezone
              readOnly: true
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
```

## Env variable

* CHRONYD_ARGS - `chronyd` arguments (default: `-d -s`)
* CHRONY_POOL - ntp pool address (default: `pool.ntp.org`)
* CHRONY_CMD_ALLOW - allow cmd (`cmdallow`) CIDRs, comma separated list (default: `127.0.0.0/8`)
* CHRONY_ALLOW - allow (`allow`) CIDRs, comma separated list (default: `127.0.0.0/8`)
* CHRONY_SYNC_RTC - enable syncing local clock (`rtcsync`) (default: `false`)
