## Selkies node init image cache

## Description

Example showing how to speed up node creation by loading cached images from a read-only persistent disk.

Many of the Selkies images are large, >1GB, this increases the initial node startup time significantly in an environment where autoscaling is critical to cost savings.

This optimization is implemented using a DaemonSet with the read-only persistent disk mounted as a volume claim.

The DaemonSet does the following on host:

1. Creates bind mounts for all of the layers found on the persistent disk into the `/var/lib/docker/overlay2` layer cache directory.
2. Mounts an overlayfs on top of `/var/lib/docker/image` that merges the directory on the host with the directory on the persistent disk.
3. Merges the `/var/lib/docker/image/overlay2/repositories.json` with the host and persistent disk json files using `jq`. This makes all the new images visible for example when when running `docker images`.
4. Restarts the docker daemon by running `systemctl restart docker`, this forces docker to reload the layer and image cache, fully registering the injected images.

> NOTE: this approach is not stable across node reboots as the layer filesystem mounts are not persistent.

![Diagram](./image-cache-diagram.png)

## Dependencies

- App Launcher: [v1.0.0+](https://github.com/selkies-project/selkies/tree/v1.0.0)
- WebRTC Streaming Stack: [v1.4.0+](https://github.com/selkies-project/selkies-vdi/tree/v1.4.0) (images only)

## Features

- Accelerated node startup by skiping large image downloads.
- Uses Packer to build GCE disk image with cached docker images.
- Periodic execution with CronJob.

## Tutorials

## Pre-requisites

This tutorial requires that you have already deployed the Kubernetes App Launcher Operator in your GKE cluster.

If you have not already deployed the operator, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/selkies-project/selkies&cloudshell_git_branch=master&cloudshell_tutorial=setup/README.md)

This tutorial requires that you have deployed the WebRTC streaming app launcher stack to the cluster.

If you have not installed the WebRTC stack, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/selkies-project/selkies-vdi&cloudshell_git_branch=master&&cloudshell_tutorial=tutorials/gke/00_Setup.md)

## Install as a CronJob

1. Set variables to install CronJob:

```bash
PROJECT_ID=YOUR_PROJECT
```
> replace `YOUR_PROJECT` with your project ID.

```bash
CRONJOB_REGION=YOUR_CLUSTER_REGION
```
> replace `YOUR_CLUSTER_REGION` with the region you want to install the cronjob to. There should only be one cluster per project with the CronJob.

```bash
IMAGE_BUILD_REGION=YOUR_BUILD_REGION
IMAGE_BUILD_ZONE=YOUR_BUILD_ZONE
```
> replace `YOUR_BUILD_REGION` and `YOUR_BUILD_ZONE` with the region and zone you want Packer to run in. Your project VPC must have a subnet in this region.

```bash
DISK_SIZE_GB=256
```
> Update this to match your estimated image usage.

3. Install the CronJob:

```bash
gcloud builds submit --config cloudbuild-install-cronjob.yaml \
    --project ${PROJECT_ID?} \
    --substitutions=_CRONJOB_REGION=${CRONJOB_REGION?},_IMAGE_BUILD_REGION=${IMAGE_BUILD_REGION?},_IMAGE_BUILD_ZONE=${IMAGE_BUILD_ZONE?},_DISK_SIZE_GB=${DISK_SIZE_GB?}
```
> NOTE: the default schedule for the CronJob is to run every 8 hours.

## Triggering the Build Manually

After installing the CronJob, it can be triggered manually using the command below:

```bash
kubectl create job --from=cronjob/update-image-cache -n pod-broker-system manual
```

## Resetting the image cache

By default, the image cache will use the previous disk image to update the images.

To completely rebuild the image cache from scratch, delete all of the Compute Images prefixed with: `selkies-image-cache-` then re-run the CronJob.
