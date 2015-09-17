# kube-consul

*PROOF OF CONCEPT*

## Introduction

The (kube-consul) integration is aimed at customers with existing Consul infrastructure that wishes to re-use this infrastructure along with Kubernetes. This would allow the possibility of integrating non-container services easily with Kubernetes.

[See issue #55 for further details](https://github.com/CiscoCloud/kubernetes-ansible/issues/55)

## Functionality Requirements

- Service Discovery via Consul
- DNS lookup services
- Key/Value storage
- API driven

## Implementation details

The implementation currently consists of three containers running in a POD. The three containers are:

1. **kubectl**
    * Container running kubectl proxy which exposes the Kubernetes API on the PODs "localhost"

2. **kube2consul**
    * Bridge between Kubernetes and Consul. Listens for events from Kubernetes and relays this back to Consul. When it's successfully connected, it logs the following:

    ```shell
    I0902 13:52:14.296118       1 kube2consul.go:140] Consul agent found: http://127.0.0.1:8500
    I0902 13:52:14.296325       1 kube2consul.go:179] Using http://127.0.0.1:8080 for kubernetes master
    I0902 13:52:14.296332       1 kube2consul.go:180] Using kubernetes API v1
    ```
3. **consul-agent**
    * Container running the Consul agent. Configuration is stored in /opt/consul/config. Successfull discovery of services would output the following in the logs:

    ```shell
    2015/09/02 13:52:14 [INFO] raft: Node at 10.0.95.7:8300 [Candidate] entering Candidate state
    2015/09/02 13:52:14 [INFO] raft: Election won. Tally: 1
    2015/09/02 13:52:14 [INFO] raft: Node at 10.0.95.7:8300 [Leader] entering Leader state
    2015/09/02 13:52:14 [INFO] consul: cluster leadership acquired
    2015/09/02 13:52:14 [INFO] consul: New leader elected: kube-consul-v1-fxz3y
    2015/09/02 13:52:14 [INFO] raft: Disabling EnableSingleNode (bootstrap)
    2015/09/02 13:52:14 [INFO] consul: member 'kube-consul-v1-fxz3y' joined, marking health alive
    2015/09/02 13:52:15 [INFO] agent: Synced service 'redis-slave'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'kibana-logging'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'kube-dns'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'monitoring-grafana'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'monitoring-influxdb'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'monitoring-heapster'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'consul'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'kubernetes'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'redis-master'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'elasticsearch-logging'
    2015/09/02 13:52:15 [INFO] agent: Synced service 'kube-ui'
    2015/09/02 14:33:41 [INFO] agent: Synced service 'kubernetes'
    2015/09/02 14:33:41 [INFO] agent: Synced service 'elasticsearch-logging'
    2015/09/02 14:33:41 [INFO] agent: Synced service 'kibana-logging'
    2015/09/02 14:33:41 [INFO] agent: Synced service 'kube-consul'
    ```


Below is a description of an existing POD used for testing.

```shell
Name:				kube-consul-v1-fxz3y
Namespace:			kube-system
Image(s):			gcr.io/google_containers/kubectl:v0.18.0-120-gaeb4ac55ad12b1-dirty,ldejager/consul-agent,ldejager/kube2consul
Node:				k8s-node-04/10.10.10.6
Labels:				k8s-app=kube-consul,kubernetes.io/cluster-service=true,version=v1
Status:				Running
Reason:
Message:
IP:				10.0.95.7
Replication Controllers:	kube-consul-v1 (1/1 replicas created)
Containers:
  kubectl:
    Image:	gcr.io/google_containers/kubectl:v0.18.0-120-gaeb4ac55ad12b1-dirty
    Limits:
      cpu:		100m
      memory:		50Mi
    State:		Running
      Started:		Wed, 02 Sep 2015 14:52:13 +0100
    Ready:		True
    Restart Count:	0
  consul-agent:
    Image:	ldejager/consul-agent
    Limits:
      cpu:		100m
      memory:		50Mi
    State:		Running
      Started:		Wed, 02 Sep 2015 14:52:13 +0100
    Ready:		True
    Restart Count:	0
  kube2consul:
    Image:	ldejager/kube2consul
    Limits:
      cpu:		100m
      memory:		50Mi
    State:		Running
      Started:		Wed, 02 Sep 2015 14:52:14 +0100
    Ready:		True
    Restart Count:	0
Conditions:
  Type		Status
  Ready 	True
No events.
```

## Validation

* DNS resolution for discovered services

```shell
/ # dig @127.0.0.1 -p 8600 monitoring-heapster.service.dc1.consul. ANY

; <<>> DiG 9.10.2-P4 <<>> @127.0.0.1 -p 8600 monitoring-heapster.service.dc1.consul. ANY
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 53710
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;monitoring-heapster.service.dc1.consul.	IN ANY

;; ANSWER SECTION:
monitoring-heapster.service.dc1.consul.	0 IN A	10.254.70.176

;; Query time: 1 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1)
;; WHEN: Thu Sep 17 10:10:06 UTC 2015
;; MSG SIZE  rcvd: 110
```

* Key/Value storage

```shell
/ # curl -X PUT -d 'monitoring-heapster.service.dc1.consul' http://127.0.0.1:8500/v1/kv/0.70.254.10.IN-ADDR.ARPA/10.254.70.176
true/
.
```

* Key/Value retrieval

```shell
/ # curl http://127.0.0.1:8500/v1/kv/?recurse
[{"CreateIndex":85,"ModifyIndex":85,"LockIndex":0,"Key":"0.70.254.10.IN-ADDR.ARPA/10.254.70.176","Flags":0,"Value":"bW9uaXRvcmluZy1oZWFwc3Rlci5zZXJ2aWNlLmRjMS5jb25zdWw="}]/
.
```

## TODO

- Review YAML files, especially ports listed and remove/add as required.
- Test Key/Value storage
- Test test test.

## Known Issues

- No support for nested DNS
- Others?

## Milestones

Based on the outcomes of the proof of concept, decisions around whether to commit development effort to port the latest kube2sky needs to be discussed and decided by PM.
