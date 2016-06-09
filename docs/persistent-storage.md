This document explains how to use persistent storage for pods.
The storage is provided by OpenStack Cinder service which is configured by using
cloud provider options in Kubernetes.

The cloud provider is disabled by default, enable it in `group_vars/all.yml`:
```
enable_cloud_provider: true
```
Re-run the playbooks to apply the configuration change.

Before using the volumes, you need to provision the underlying storage.
First, create required number of volumes in Cinder, for example, using
the following command:
```
openstack volume create --size 5 k8s-vol-001
```

For each of the created volumes, you need to provision `PersistentVolume`
resource in the Kubernetes cluster. Here is an example:
```
vi pv001.yml

kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv001
  labels:
    type: local
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  cinder:
    fsType: "ext4"
    volumeID: "XXX"

kubectl create -f pv001.yml
kubectl get pv
```
Replace value of `volumeID` with the corresponding ID of a Cinder volume.

Now users can use the `PersistentVolumeClaim` resource to request storage for
their pods:

```
vi pvc001.yml

apiVersion: v1
kind: PersistentVolumeClaim 
metadata:
  name: myclaim-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi

kubectl create -f pvc001.yml
kubectl get pvc
```

Claims can request specific size and access mode.

More information about persistent volumes and how to use them are available in
the official [docs](https://github.com/kubernetes/kubernetes/blob/master/docs/user-guide/persistent-volumes.md)

### Issues

1) If you have Kubernetes nodes with the same names in Nova (for example,
you deployed 2 clusters in different private networks in the same tenant),
`kubelet` will fail to match and assign Cinder volumes to correct nodes.
Related issue: https://github.com/kubernetes/kubernetes/issues/11543

