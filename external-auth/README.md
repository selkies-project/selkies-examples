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

## Programmatic Access

### Google Provider

1. Save your GCIP API key to a variable:

```
export API_KEY=YourApiKey
```
> NOTE: This is obtained from the Identity Platform Cloud Console page under __Application Setup Details__

2. Save the OAuth Client ID of the GCIP sign-in page to a variable:

```
AUDIENCE=YourGcipClientID
```
> NOTE: This is obtained from the Credentials Cloud Console page for the OAuth client named __Web client (auto created by Google Service)__

3. If running from a GCP instance or GKE container with Workload Identity, obtain an ID token from the metadata server:

```
ID_TOKEN=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=${AUDIENCE?}")
```

4. Obtain a GCIP ID token from the Identity Platform API:

```
GCIP_TOKEN=$(curl -s "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${API_KEY?}" \
    -H 'Content-Type: application/json' \
    --data-binary '{
        "postBody": "id_token='${ID_TOKEN?}'&providerId=google.com",
        "requestUri": "https://broker.endpoints.${PROJECT_ID?}.cloud.goog",
        "returnIdpCredential": true,
        "returnSecureToken": true
    }' | jq -r .idToken)
```
> NOTE: The GCIP ID token is returned in the `idToken` field of the JSON response.
> NOTE: you may have to update the `requestUri` in the request to match your broker endpoint.

5. Make a proxied request to broker using GCIP token:

```
curl -s -H "Authorization: Bearer ${GCIP_TOKEN}" -H "x-broker-proxy-user: user@example.com" "https://broker.endpoints.${PROJECT_ID?}.cloud.goog/broker/"
```
> NOTE: change the value of `x-broker-proxy-user` to the user email you want to make the request as.
