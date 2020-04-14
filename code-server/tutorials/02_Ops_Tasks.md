## Operational Tasks

This is part of a multi-part tutorial series and assumes you have run the **Connecting** section already:

- `teachme tutorials/02_Connecting.md`

Other sections include:

- `teachme tutorials/00_Setup.md`
- `teachme tutorials/01_Deploy.md`
- `teachme tutorials/02_Connecting.md`
- `teachme tutorials/03_Developer_Workflow.md`

This tutorial will walk you through the following:

- Authorizing new users
- Resizing user persistent disks.
- Creating backups of persistent disks.
- Deleting a users disk.
- Updating the base cloudshell image
- Testing changes in the staging environment

## Authorizing new users

There are multiple ways to authorize access to the pod broker, from the Cloud Console, Google Cloud SDK, or the provided script.

1. Follow the docs on [Setting up IAP access](https://cloud.google.com/iap/docs/enabling-kubernetes-howto#iap-access) to add authorized members.

2. Example adding your user email using the provided script:

```bash
~/code-server-gke/scripts/add_iap_user.sh user $(gcloud config get-value account)
```
  > NOTE: you can also use this script to add groups and domains:

  > `USAGE: ./scripts/add_iap_user.sh <user|group|domain> <member> [project id]`

## Resizing persistent disks

Google Compute Engine and Google Kubernetes Engine supports resizing of persistent disks after they have been created.

1. Obtain the name of the PersistentVolumeClaim for the user whos disk you want to resize:

```bash
kubectl get pvc -o json | jq -r '.items[] | "\(.metadata.name)\t \(.metadata.annotations."pod.broker/user")\t \(.spec.resources.requests.storage)"'
```
> NOTE: The name will be in the form of: `persist-code-server-XXXXXXXXXX-code-0`

2. Edit the persistentvolumeclaim and change the .spec.resources.requests.storage to the new value. 

```
kubectl edit USER_PVC_NAME
```

3. From the main code server launcher web interface, shutdown and re-launch the pod. When the pod starts up again, the disk will we be resized and ready to use.

## Deleting a users disk

1. From the main code server launcher web interface, shutdown the user pod with the attached disk.

2. Obtain the name of the PersistentVolumeClaim for the user whos disk you want to delete:

```bash
kubectl get pvc -o json | jq -r '.items[] | "\(.metadata.name)\t \(.metadata.annotations."pod.broker/user")\t \(.spec.resources.requests.storage)"'
```
> NOTE: The name will be in the form of: `persist-code-server-XXXXXXXXXX-code-0`

3. Delete the PersistenVolumeClaim associated with the user:

```
kubectl delete pvc USER_PVC_NAME
```
> NOTE: The PersistentVolume and corresponding Compute Engine Disk will be automatically deleted. The next time the user launches code-server, a new disk will be provisioned.
