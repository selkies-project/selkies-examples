# Selkies - Configure a Custom Domain

## Overview

The following document describes how to configure a custom domain for the App Launcher of a Selkies Deployment.

## Steps

### Step 1: DNS Configuration

Add a CNAME record to the custom domain on the DNS provider or register, using the Default App Launcher domain as the value for the CNAME.

```markdown
Default App Launcher domain: broker.endpoints.${PROJECT_ID?}.cloud.goog

Where PROJECT_ID is the GCP Project ID of the created deployment.
```

| Record type | Host               | Value                                      |
|-------------|--------------------|--------------------------------------------|
| CNAME       | custom.example.com | broker.endpoints.${PROJECT_ID?}.cloud.goog |

Allow up to 24 hours for the propagation of the created CNAME record, this process normally takes a few minutes though.

### Step 2: Create/Update the Secret Manager Secrets

#### Automated pipeline to create the secrets

Declare variables needed for the automated pipeline where:

- `_REGION`: cluster region
- `_CUSTOM_DOMAIN`: this variable is used to especify the custom domain for the App Launcher Portal.
- `_LB_DOMAINS`: is the list of additional domains to add to the managed certificate and configure in the cluster Load Balancer.

```bash
export _REGION=REPLACE_WITH_VALID_REGION
export _CUSTOM_DOMAIN="custom.example.com"
export _LB_DOMAINS="custom.example.com,another.example.com"
```

Execute pipeline

```bash
gcloud builds submit --project ${PROJECT_ID?} --substitutions=^--^_ACTION=apply--_REGION=${_REGION}--_CUSTOM_DOMAIN=${_CUSTOM_DOMAIN}--_LB_DOMAINS=${_LB_DOMAINS}
```

#### Create secrets manually

##### Update the project load balancer to use the DNS record and provision a Managed SSL Certificate.

Create or update the broker-tfvars-lbdomains secret with the following content:
additional_ssl_certificate_domains = [
    "${CUSTOM_DOMAIN}"
]

From the Selkies core repo, `setup/infra` subdirectory, run cloud build to preview then apply the domain change.

```bash
cd PATH_TO_YOUR_SELKIES_REPO_DIR
cd setup/infra
gcloud builds submit --project ${PROJECT_ID?} --substitutions=_ACTION=plan
gcloud builds submit --project ${PROJECT_ID?} --substitutions=_ACTION=apply
```

Allow some time for the SSL certificate to be provisioned, this may take up to 24 hours after the CNAME is pointed to the Default App Launcher domain. In most cases, propagation of the records and provisioning of the SSL certificate will happen within a few hours, depending on the domain provider.

##### Create broker-custom-domain secret

Custom domain secret  broker-custom-domain, this information is pulled during the manifest deployment step to configure the pod-broker with the configured domain.

```bash
gcloud secrets create  broker-custom-domain --replication-policy=automatic --data-file - <<EOF
${CUSTOM_DOMAIN}?
EOF
```

From the selkies repo, re-deploy the manifests from the selkies repo, `setup/manifests` directory to roll out the custom domain change.

##### Update the broker-logout-url secret

To properly redirect the browser to the correct url, the `secret broker-logout-url` has to be updated with the custom domain.

```bash
gcloud secrets versions add broker-logout-url --data-file=-
<<EOF
"https://${CUSTOM_DOMAIN}?gcp-iap-mode=GCIP_SIGNOUT"
EOF
```

### Step 3: Apply infra changes

From the Selkies core repo, `setup/infra` subdirectory, run cloud build to apply the domain change.

```bash
cd PATH_TO_YOUR_SELKIES_REPO_DIR
cd setup/infra
gcloud builds submit --project ${PROJECT_ID?} --substitutions=_ACTION=apply
```

Allow some time for the SSL certificate to be provisioned, this may take up to 24 hours after the CNAME is pointed to the Default App Launcher domain. In most cases, propagation of the records and provisioning of the SSL certificate will happen within a few hours, depending on the domain provider.

### Step 4: Re-deploy manifests

From the selkies repo, re-deploy the manifests from the selkies repo, `setup/manifests` directory to roll out the previusly configured changes.

```bash
cd PATH_TO_YOUR_SELKIES_REPO_DIR
cd setup/manifests
gcloud builds submit --project ${PROJECT_ID?}
```

### Step 5: Reinstall PWAs (Optional)

If any PWAs were installed, will need to be re-installed after being launched from the new URL.