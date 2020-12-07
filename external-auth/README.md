# IAP External Identity Provider Addon

Configures Selkies to use an [external identity provider](https://cloud.google.com/iap/docs/external-identities).

## Prerequisites

1. Requires selkies deployment with at least Istio 1.7

## Install Open Policy Agent

1. Select an OPA rego policy file from the `policies/` directory and save to variable:

```bash
export POLICY=policies/allow-all.rego
```

2. Set your cluster project and region:

```bash
export PROJECT_ID=$(gcloud config get-value project)
```

```bash
export REGION=us-west1
```

3. Run Cloud Build to create manifests and policy:

```bash
gcloud builds submit --project ${PROJECT_ID?} --substitutions=_REGION=${REGION?},_POLICY=${POLICY?}
```

## Enable Identity Platform

1. Enable external identities for IAP:
    a. Open the (IAP console page)[] and select the `istio-ingressgateway` resource.
    b. On the side info panel, click __START__ next to the "Use external identities for authorization" section.
    c. If prompted, enable the __Identity Toolkit API__.


## (WIP) - Install Ping Federate

1. If you don't already have a [Ping Federate](https://www.pingidentity.com/en/software/pingfederate.html) account, create one now.
2. Deploy Ping Federate to your cluster:

```bash
git clone https://github.com/pingidentity/pingidentity-devops-getting-started.git
cd pingidentity-devops-getting-started/20-kubernetes/06-clustered-pingfederate
```