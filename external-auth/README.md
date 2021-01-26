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

4. Create a ConfigMap to authorize your user:

```bash
EMAIL=$(gcloud config get-value account)
```

```
cat - > policies/users.json <<EOF
{
    "allowed_users": [
        "${EMAIL}"
    ]
}
EOF
```

```bash
kubectl -n opa create configmap selkies-opa-users \
    --from-file policies/users.json \
    --dry-run=client -o yaml | \
        kubectl label -f- --dry-run=client -o yaml --local openpolicyagent.org/data=opa | \
            kubectl apply -f -
```

> NOTE: the json content in this configmap is automatically loaded using the kube-mgmt sidecar. See also: https://github.com/open-policy-agent/kube-mgmt#json-loading

## Enable Identity Platform

1. Enable external identities for IAP:
    a. Open the (IAP console page)[] and select the `istio-ingressgateway` resource.
    b. On the side info panel, click __START__ next to the "Use external identities for authorization" section.
    c. If prompted, enable the __Identity Toolkit API__.
