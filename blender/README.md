## Blender 3D Demo

This demo shows how to stream an instance of Blender 3D using the GKE WebRTC VDI stack.

This tutorial will walk you through the following:

- Verifying cluster pre-requisites.
- Building the image and deploying the manifests with Cloud Build.

## Setup

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```bash
export PROJECT=YOUR_PROJECT
```

```bash
gcloud config set project ${PROJECT}
```

## Pre-requisites

This tutorial requires that you have already deployed the Kubernetes App Launcher Operator in your GKE cluster.

If you have not already deployed the operator, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/k8s-stateful-workload-operator&cloudshell_git_branch=v1.0.0&cloudshell_tutorial=setup/README.md)

This tutorial requires that you have deployed the WebRTC streaming app launcher stack to the cluster.

If you have not installed the WebRTC stack, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/webrtc-gpu-streaming&cloudshell_git_branch=v1.0.0&&cloudshell_tutorial=tutorials/gke/00_Setup.md). 

## Platform verification

1. Obtain cluster credentials for the cluster in us-west1:

```bash
gcloud --project ${PROJECT} container clusters get-credentials broker-us-west1 --region us-west1
```

2. Verify that the WebRTC streaming manifest bundle is present:

```bash
kubectl get configmap webrtc-gpu-streaming-manifests-1.0.0 -n default
```

3. Verify that GPU sharing is enabled:

```bash
kubectl describe node -l cloud.google.com/gke-accelerator-initialized=true | grep nvidia.com/gpu
```

Example output:

```
 nvidia.com/gpu:             48
 nvidia.com/gpu:             48
```

> Verify that the number of availble GPUs is greater than 1.

## Build the app image

1. Build the container image using cloud build:

```bash
(cd images && gcloud builds submit)
```

## Deploy the app manifests

1. Deploy manifests to the cluster:

```bash
gcloud builds submit --substitutions=_REGION=us-west1
```

> NOTE: change the value of _REGION to target a different region.

2. Open the app launcher web interface and launch the app.

> NOTE: after the Cloud Build has completed from the previous step, it will take a few minutes for the nodes to pre-pull the image. As a result, the first launch may take longer than usual.
