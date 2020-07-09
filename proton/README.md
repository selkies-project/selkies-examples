## Proton Example

## Description

This example shows how to use [Valve Software's Proton](https://github.com/ValveSoftware/Proton) for streaming windows applications.

## Dependencies

- Selkies App Launcher: [v1.0.0+](https://github.com/GoogleCloudPlatform/selkies/tree/v1.0.0)
- Selkies VDI Stack: [v1.4.0+](https://github.com/GoogleCloudPlatform/selkies-vdi/tree/v1.4.0)
- Selkies VDI Proton Images: [proton](https://github.com/GoogleCloudPlatform/selkies-vdi/tree/v1.4.0/images/proton)

## Features

- Build Proton from source using Cloud Build.
- Base image that can be used for app streaming.

## Installed Software

- Proton

## Tutorials

This tutorial will walk you through the following:

- Verifying cluster pre-requisites.
- Building the images and deploying a sample windows app.

## Setup

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```bash
export PROJECT_ID=YOUR_PROJECT
```

```bash
gcloud config set project ${PROJECT_ID?}
```

## Pre-requisites

This tutorial requires that you have already deployed the Kubernetes App Launcher Operator in your GKE cluster.

If you have not already deployed the operator, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/selkies&cloudshell_git_branch=v1.0.0&cloudshell_tutorial=setup/README.md)

This tutorial requires that you have deployed the WebRTC streaming app launcher stack to the cluster.

If you have not installed the WebRTC stack, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/selkies-vdi&cloudshell_git_branch=v1.0.0&&cloudshell_tutorial=tutorials/gke/00_Setup.md). 

Make sure you also build the proton images in the selkies-vdi repo:

```
(cd images/proton && gcloud builds submit)
```

## Build the images

1. Build the container images using Cloud Build:

```bash
(cd images && gcloud builds submit)
```

## Deploy the app manifests

1. Deploy manifests to the cluster:

```bash
(cd manifests && gcloud builds submit --substitutions=_REGION=${REGION?})
```

2. Open the app launcher web interface and launch the app.

> NOTE: after the Cloud Build has completed from the previous step, it will take a few minutes for the nodes to pre-pull the image. As a result, the first launch may take longer than usual.
