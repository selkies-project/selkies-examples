## Shared storage example for Selkies

This example shows how to use the shared storage feature of the WebRTC Streaming addon.

## BrokerAppConfig params

The following BrokerAppConfig appParams apply to shared storage:

 - `enableSharedStorage`: `true` or `false` to enable shared storage feature. Default: `false`
 - `sharedStorageClass`: name of the storageclass. Default: `""`.
 - `sharedVolumeMode`: Access mode for volume. Default: `ReadWriteMany`.
 - `sharedVolumeName`: Name of PersistentVolume to attach claim to, not applicable if using `sharedStorageClass` and dynamic provisioning. Default: `""`.
 - `sharedStorageSize`: Size of the storage request. Default: `1Gi`.
 - `sharedStorageMountPath`: Mount path in the desktop container to mount the shared volume subpath to. Default: `/mnt/shared`.
 - `sharedStorageSubPath`: Subpath within the shared volume to provision, an initContainer will set the appropriate permissions on this subpath. Use this to separate tenants across multiple apps on the same shared volume. Default: `data`. 

> Important: at this time, only one type of shared storage is supported per app. If you switch between shared storage types, you must first delete the PVC created for the user before it will be re-created with the new type.

## NFS shared storage with Cloud Filestore

This use case shows how to provision a Cloud Filestore instance shared across all broker apps, isolated by subdirectory.

Pros:
  - Good for hosting several broker apps with data that can co-locate with other tenants.
  - Filestore is a managed service, no infrastructure to operate.

Cons:
  - All tenants data co-located on single instance. You can create multiple instances for increased isolation but this is more expensive.
  - Minimum instance size (and cost) is 1TB.

### Cloud Filestore tutorial

1. Create cloud filestore instance:

```bash
(cd infra && gcloud builds submit)
```

2. Deploy the manifests:

```bash
(cd manifests && gcloud builds submit)
```

3. Modify your BrokerAppConfig with the following AppParams:

```
appParams:
  - name: enableSharedStorage
    default: "true"
  - name: sharedVolumeName
    default: "broker-shared-storage-us-west1-a"
  - name: sharedStorageMountPath
    default: "/mnt/shared"
  - name: sharedStorageSubPath
    default: "app1"
```

4. Launch the app and verify that the mount at /mnt/shared is 1TB in size and that you can write to it.

## NFS shared storage with Rook

This use case shows how to provision a separate NFS server backed by an independent persistent disk per broker app.

Pros:
  - Good for small number of tenants. Data for each app is stored on separate persistent disks.
  - Increased data isolation.
  - No minimum disk size, unless large IOPS is required.

### Rook NFS tutorial

1. Install the Rook operator:

```bash
kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-1.3/cluster/examples/kubernetes/nfs/operator.yaml
```

2. Create the NFSServer backed by GCE PD in the rook-nfs namespace.

```
cat - | kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: rook-nfs
---
# A default storageclass must be present
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-default-claim
  namespace: rook-nfs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: nfs.rook.io/v1alpha1
kind: NFSServer
metadata:
  name: rook-nfs
  namespace: rook-nfs
spec:
  serviceAccountName: rook-nfs
  replicas: 1
  exports:
    - name: share1
      server:
        accessMode: ReadWrite
        squash: "none"
      # A Persistent Volume Claim must be created before creating NFS CRD instance.
      persistentVolumeClaim:
        claimName: nfs-default-claim
EOF
```

3. Create a new StorageClass to enable dynamic provisioning:

```
cat - | kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  labels:
    app: rook-nfs
  name: rook-nfs-share1
parameters:
  exportName: share1
  nfsServerName: rook-nfs
  nfsServerNamespace: rook-nfs
provisioner: rook.io/nfs-provisioner
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
```

4. Modify your BrokerAppConfig with the following AppParams:

```
appParams:
  - name: enableSharedStorage
    default: "true"
  - name: sharedStorageClass
    default: "rook-nfs-share1"
  - name: sharedStorageMountPath
    default: "/mnt/shared"
  - name: sharedStorageSubPath
    default: "app1"
```

5. Launch the app and verify that the /mnt/shared directory is 10gig in size and that you can write to it.

## Shared read-only persistent disk

Pros:
  - Large assets can be stored on a persistent disk and mounted by multiple pods on different nodes in the same zone.
  - Attaching the disk is fast, part of default k8s provisioner.

Cons:
  - Data is read-only.
  - Disk must be created in same zone(s) as node(s).

### Read-only PD tutorial

1. Create a persistent disk in the same zone as the GKE nodes.
2. Create a new PersistentVolume that attaches to the existing disk.

```bash
cat - | kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: broker-shared-ro-pd-us-west1-a
spec:
  storageClassName: ""
  capacity:
    storage: 100Gi
  accessModes:
    - ReadOnlyMany
  gcePersistentDisk:
    pdName: shared-pd-test
    fsType: ext4
    partition: 1
    readOnly: true
EOF
```

> NOTE: `spec.gcePersistentDisk.partition` is set to 1 because this disk was created as a boot disk.

3. Modify your BrokerAppConfig with the following AppParams:

```
appParams:
  - name: enableSharedStorage
    default: "true"
  - name: sharedVolumeName
    default: "broker-shared-ro-pd-us-west1-a"
  - name: sharedStorageMountPath
    default: "/mnt/shared"
  - name: sharedStorageSubPath
    default: "var/lib"
  - name: sharedVolumeMode
    default: "ReadOnlyMany"
```

NOTE: the `sharedStoragePath` is a path relative to `/` on the disk.

4. Launch the app and verify that the contents of `/var/lib` is present on `/mnt/shared` and that the path is read only.
