## Shared storage example for Selkies

This example shows how to use the shared storage feature of the WebRTC Streaming addon.

## BrokerAppConfig params

The following BrokerAppConfig appParams apply to shared storage:

 - `enableSharedStorageNFS`: `true` or `false` to enable shared storage with NFS feature. Default: `false`
 - `sharedStorageNFSSize`: Size of the storage request. Default: `1Gi`.
 - `sharedStorageNFSMountPath`: Mount path in the desktop container to mount the shared volume subpath to. Default: `/mnt/shared`.
 - `sharedStorageNFSSubPath`: Subpath within the shared volume to provision, an initContainer will set the appropriate permissions on this subpath. Use this to separate tenants across multiple apps on the same shared volume. Default is the app name. 

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

3. Get the IP address of the Filestore instance:

```bash
PROJECT_ID=$(gcloud config get-value project)
```

```bash
gsutil cat gs://${PROJECT_ID?}-broker-tf-state/broker/broker-filestore.tfstate | jq -r '.outputs."filestore-ip".value'
```

4. Modify your BrokerAppConfig with the following AppParams to enabled the shared volume and persist the home directory to NFS:

```
appParams:
  - name: enableSharedStorageNFS
    default: "true"
  - name: sharedStorageNFSSize
    default: "10Gi"
  - name: sharedStorageNFSMountPath
    default: "/mnt/shared"
  - name: sharedStorageNFSServer
    default: "FILESTORE_IP"
  - name: sharedStorageNFSShare
    default: "/data"
  - name: enablePersistence
    default: "true"
  - name: persistStorageClass
    default: "broker-shared-filestore"
```

> NOTE: replace `FILESTORE_IP` with the IP of your Filestore instance obtained earlier.

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
# Note that the backing PV will use the default storage class
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: broker-shared-rook
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
  name: broker-shared-rook
  namespace: rook-nfs
spec:
  serviceAccountName: rook-nfs
  replicas: 1
  exports:
    - name: data
      server:
        accessMode: ReadWrite
        squash: "none"
      # A Persistent Volume Claim must be created before creating NFS CRD instance.
      persistentVolumeClaim:
        claimName: broker-shared-rook
EOF
```

3. Create a new StorageClass to enable dynamic provisioning of per-user persistent home directory storage:

```
cat - | kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: broker-shared-rook
parameters:
  exportName: data
  nfsServerName: broker-shared-rook
  nfsServerNamespace: rook-nfs
provisioner: rook.io/nfs-provisioner
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
```

4. Obtain the IP of the Rook pod:

```bash
kubectl get endpoints broker-shared-rook -n rook-nfs -o jsonpath='{.subsets..addresses..ip}'
```

5. Modify your BrokerAppConfig with the following AppParams to enabled the shared volume and persist the home directory to NFS:

```
appParams:
  - name: enableSharedStorageNFS
    default: "true"
  - name: sharedStorageNFSSize
    default: "10Gi"
  - name: sharedStorageNFSMountPath
    default: "/mnt/shared"
  - name: sharedStorageNFSServer
    default: "ROOK_IP"
  - name: sharedStorageNFSShare
    default: "/broker-shared-rook"
  - name: enablePersistence
    default: "true"
  - name: persistStorageClass
    default: "broker-shared-rook"
  - name: persistStorageSize
    default: "10Gi"
  - name: persistStorageSubPath
    default: "USER"
```

> NOTE: Replace `ROOK_IP` with the IP of the rook pod obtained earlier.

6. Launch the app and verify that the /mnt/shared directory is 10gig in size and that you can write to it.

## Shared read-only persistent disk

Pros:
  - Large assets can be stored on a persistent disk and mounted by multiple pods on different nodes in the same zone.
  - Attaching the disk is fast, part of default k8s provisioner.

Cons:
  - Data is read-only.
  - Disk must be created in same zone(s) as node(s).

### WIP - Read-only PD tutorial

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
  - name: enableSharedStorageROPD
    default: "true"
  - name: sharedVolumeNameROPD
    default: "broker-shared-ro-pd-us-west1-a"
  - name: sharedStorageMountPathROPD
    default: "/mnt/shared"
  - name: sharedStorageSubPathROPD
    default: "var/lib"
  - name: sharedVolumeModeROPD
    default: "ReadOnlyMany"
```

NOTE: the `sharedStorageSubPathROPD` is a path relative to `/` on the disk.

4. Launch the app and verify that the contents of `/var/lib` is present on `/mnt/shared` and that the path is read only.
