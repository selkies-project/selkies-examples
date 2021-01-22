## Visual Studio Code Server on GKE

This is the initial setup tutorial in the multi-part series.

This repository shows you how to deploy the [Code Server app](https://github.com/cdr/code-server) with a top-level URL.

Other sections include: 

- `teachme tutorials/01_Developer_Workflow.md`
- `teachme tutorials/02_Ops_Tasks.md`

This repository shows you how to deploy the [Code Server app](https://github.com/cdr/code-server) with a top-level URL.

This tutorial will walk you through the following:

- Verifying cluster pre-requisites.
- Creating DNS recordss.
- Building the container images.
- Deploying the manifests.

## Pre-requisites

This tutorial requires that you have already deployed the Kubernetes App Launcher Operator in your GKE cluster.

If you have not already deployed the operator, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/selkies-project/selkies&cloudshell_git_branch=master&cloudshell_tutorial=setup/README.md)

## Setup

1. Clone the source repo and change to the examples directory:

```bash
git clone https://github.com/selkies-project/selkies-examples.git && \
  cd selkies-examples/code-server
```

2. Set the project, replace `YOUR_PROJECT` with your project ID:

```bash
export PROJECT_ID=YOUR_PROJECT
```

```bash
gcloud config set project ${PROJECT_ID?}
```

3. Obtain cluster credentials:

```bash
REGION=us-west1
```

> NOTE: change this to the region of your cluster.

```bash
gcloud container clusters get-credentials broker-${REGION?} --region ${REGION?}
```

## DNS record with Cloud Endpoints

1. Obtain the broker ingress IP:

```bash
export EXTERNAL_IP=$(dig +short broker.endpoints.${PROJECT_ID?}.cloud.goog)
```

2. Create cloud endpoint DNS record that points to the broker ingress IP:

```bash
./scripts/create_cloudep.sh code ${EXTERNAL_IP?}
```

3. Create cloud endpoint DNS records for the port-forward capability:

```bash
for port in 3000 8000 8080; do ./scripts/create_cloudep.sh code-port-${port} ${EXTERNAL_IP}; done
```

## Update Load Balancer Certificates

1. Create a new Secret Manager secret containing the list of additional managed domains:

```bash
gcloud secrets create broker-tfvars-lb-domains --replication-policy=automatic --data-file - <<EOF
additional_ssl_certificate_domains = [
    "code.endpoints.${PROJECT_ID?}.cloud.goog",
    "code-port-3000.endpoints.${PROJECT_ID?}.cloud.goog.",
    "code-port-8000.endpoints.${PROJECT_ID?}.cloud.goog.",
    "code-port-8080.endpoints.${PROJECT_ID?}.cloud.goog.",
]
EOF
```

2. Show Terraform plan for the infrastructure changes:

```bash
(cd ~/selkies/setup/infra/ && gcloud builds submit --substitutions=_ACTION=plan)
```

> NOTE: verify that only the new managed certs will be created and the ssl_certificates on the target https proxy will be updated.

3. Apply the Terraform plan:

```bash
(cd ~/selkies/setup/infra/ && gcloud builds submit)
```

> NOTE: it may take several minutes for the managed certificates on the load balancer to update. This can be monitored from the Cloud Console.

## Build images

1. Build the images using Cloud Build:

```bash
(cd images && gcloud builds submit)
```

> NOTE: this will take 10-15 minutes to complete.

## Deploy manifests

1. Deploy the manifests to the cluster using Cloud Build:

```bash
gcloud builds submit --substitutions=_REGION=${REGION?}
```

2. Open the app launcher web interface to launch Code Server.

> NOTE: after the Cloud Build has completed from the previous step, it will take a few minutes for the nodes to pre-pull the image. As a result, the first launch may take longer than usual.

## Whats next

Open the next Cloud Shell Tutorial: __Developer Workflow__:

```bash
teachme ~/selkies-examples/tutorials/01_Developer_Workflow.md
```