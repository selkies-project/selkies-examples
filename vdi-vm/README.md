## Virtual Machine Controller Stack for Selkies

## Description

Launches virtual machines for users on Selkies.

## Dependencies

- App Launcher: [v1.0.0+](https://github.com/GoogleCloudPlatform/solutions-k8s-stateful-workload-operator/tree/v1.0.0)
- WebRTC Streaming Stack: [v1.4.0+](https://github.com/GoogleCloudPlatform/solutions-webrtc-gpu-streaming/tree/v1.4.0) (images only)

## Features

- Orchestration of Windows and Linux instances on GCP.
- Stream Windows desktop to browser tab using Guacamole and RDP.
- Stream Linux desktop to browser using Selkies WebRTC.

## Tutorials

This tutorial will guide you through installing the controller stack and deploying a sample VM.

## Pre-requisites

This tutorial requires that you have already deployed the Kubernetes App Launcher Operator in your GKE cluster.

If you have not already deployed the operator, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/solutions-k8s-stateful-workload-operator&cloudshell_git_branch=v1.0.0&cloudshell_tutorial=setup/README.md)

This tutorial requires that you have deployed the WebRTC streaming app launcher stack to the cluster.

If you have not installed the WebRTC stack, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/solutions-webrtc-gpu-streaming&cloudshell_git_branch=v1.0.0&&cloudshell_tutorial=tutorials/gke/00_Setup.md)

## Install core components

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```bash
export PROJECT_ID=YOUR_PROJECT
```

```bash
gcloud config set project ${PROJECT_ID?}
```

2. Build the VM control plane images:

```bash
(cd images && gcloud builds submit --project ${PROJECT_ID?})
```

3. Set the regions in the broker project that you want to deploy instances to:

```bash
gcloud secrets create vdi-vm-tfvars-subnet-regions \
  --replication-policy=automatic \
  --data-file <(cat - <<EOF
subnet_regions = ["us-west1"]
EOF
)
```

> NOTE: this Secret Manager secret is used in the terraform apply by the cloud build.

4. Provision infrastructure and deploy manifests:

```bash
REGION=us-west1
```

> NOTE: set this to your target region

```bash
gcloud builds submit --substitutions=_REGION=${REGION?}
```

> NOTE: At this point you have the control plane components installed.

## Add IAM permissions to target project

Follow the steps below if the poject you want to dpeloy instances to is different than your broker project.

1. Set project for where instances will be created:

```bash
INSTANCE_PROJECT=${PROJECT_ID?}
```

> NOTE: change this to your target instance project.

2. Grant the VM instance service account access to the broker IAP routes:

```bash
VM_DEFAULT_SA=vdi-vm-default@${INSTANCE_PROJECT?}.iam.gserviceaccount.com
```

> NOTE: change this to the email of the service account in your instance project.

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID?} --member serviceAccount:${VM_DEFAULT_SA?} --role roles/iap.httpsResourceAccessor
```

3. Grant the VM controller service account permissions on the target project:

```bash
VM_CONTROLLER_SA=vdi-vm-controller@${PROJECT_ID?}.iam.gserviceaccount.com
```

```bash
gserviceaccount.com && \
  gcloud projects add-iam-policy-binding ${INSTANCE_PROJECT?} --member serviceAccount:${VM_CONTROLLER_SA?} --role roles/compute.instanceAdmin.v1 && \
  gcloud projects add-iam-policy-binding ${INSTANCE_PROJECT?} --member serviceAccount:${VM_CONTROLLER_SA?} --role roles/iam.serviceAccountUser && \
  gcloud projects add-iam-policy-binding ${INSTANCE_PROJECT?} --member serviceAccount:${VM_CONTROLLER_SA?} --role roles/iap.tunnelResourceAccessor
```

## Deploy Windows example

1. Deploy the ComputeInstanceTemplate and BrokerAppConfig:

```bash
(cd examples/win2k19 && gcloud builds submit --substitutions=_REGION=${REGION})
```

2. Open the App Launcher and launch the app.

> NOTE: it will take about 2-3 minutes for the instance to start the first time and 1-2 minutes when resuming from shutdown.

## Deploy CentOS 7 example

1. Build the GCE image with GPU driver and pre-installed WebRTC stack:

```bash
(cd examples/centos7 && gcloud builds submit)
```

> NOTE: this step takes about 15-20 minutes to complete.

2. Deploy the ComputeInstanceTemplate and BrokerAppConfig:

```bash
(cd examples/centos7 && gcloud builds submit --substitutions=_REGION=${REGION})
```

2. Open the App Launcher and launch the app.

> NOTE: it will take about 2-3 minutes for the instance to start the first time and 1-2 minutes when resuming from shutdown.
