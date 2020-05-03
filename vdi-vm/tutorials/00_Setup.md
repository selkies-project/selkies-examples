## VM Provisioning on GKE

## Setup

1. Set project ID:

```
export PROJECT=YOUR_PROJECT
```

```bash
gcloud config set project-id $PROJECT
```

## DNS record with Cloud Endpoints

1. Obtain the broker ingress IP:

```bash
export EXTERNAL_IP=$(dig +short broker.endpoints.${PROJECT?}.cloud.goog)
```

2. Create cloud endpoint DNS record that points to the broker ingress IP:

```bash
~/kube-app-launcher/setup/scripts/create_cloudep.sh guac ${EXTERNAL_IP?}
```

## Update Load Balancer Certificates

1. Create a `lb-domains.auto.tfvars` file with the new managed cert domain names:

```
cat - | tee lb-domains.auto.tfvars <<EOF
additional_ssl_certificate_domains = [
    "guac.endpoints.${PROJECT?}.cloud.goog",
]
EOF
```

2. Move this new file to the infrastructure repo:

```bash
mv lb-domains.auto.tfvars ~/kube-app-launcher/setup/infra/
```

> NOTE: this assumes the location of the the repo from the pre-requisites. 

3. Show Terraform plan for the infrastructure changes:

```bash
(cd ~/kube-app-launcher/setup/infra/ && gcloud builds submit --substitutions=_ACTION=plan)
```

> NOTE: verify that only the new managed certs will be created and the ssl_certificates on the target https proxy will be updated.

4. Apply the Terraform plan:

```bash
(cd ~/kube-app-launcher/setup/infra/ && gcloud builds submit)
```

> NOTE: it may take several minutes for the managed certificates on the load balancer to update. This can be monitored from the Cloud Console.
