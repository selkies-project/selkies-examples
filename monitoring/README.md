## Prometheus and Grafana for Monitoring GKE Cluster

This tutorial shows you how to deploy Prometheus and Grafana to monitor Kubernetes metrics.

You will do the following:

1. Deploy the [kube-promethus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) with Helm.
2. Configure Cloud Endpoints DNS for the Grafana web interface.
3. Update the project load balancer to use the DNS record and provision a Managed SSL Certificate.
4. Deploy Istio resources to access the Grafana dashboard through the project load balancer.

## Setup

1. Clone the source repo and change to the examples directory:

```bash
git clone https://github.com/selkies-project/selkies-examples.git && \
  cd selkies-examples/monitoring
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

## Install with Helm

1. Install the helm 3 binary:

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

2. Add the repo to helm:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

3. Create a namespace for the deployment:

```bash
kubectl create ns monitoring
```

4. Install the helm chart:

```bash
helm install kube-prom-stack prometheus-community/kube-prometheus-stack -n monitoring
```

5. Test installation by creating a port forward to port 3000 on the grafana pod:

```bash
POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{..metadata.name}' | head -1)
```

```bash
kubectl port-forward --address 0.0.0.0 ${POD} -n monitoring 3000:3000
```

> Open your browser to: `http://localhost:3000`
> Login as `admin/prom-operator`

## DNS record with Cloud Endpoints

1. Obtain the broker ingress IP:

```bash
export EXTERNAL_IP=$(dig +short broker.endpoints.${PROJECT_ID?}.cloud.goog)
```

2. Create cloud endpoint DNS record that points to the broker ingress IP:

```bash
./scripts/create_cloudep.sh monitoring ${EXTERNAL_IP?}
```

## Update load balancer with Terraform

1. Create or update the `broker-tfvars-lbdomains` secret with the following content:

```hcl
additional_ssl_certificate_domains = [
    "monitoring.endpoints.gpod-dev01.cloud.goog.",
]
```

2. From the Selkies core repo, `setup/infra` subdirectory, run cloud build to preview then apply the domain change.

```bash
cd PATH_TO_YOUR_SELKIES_REPO_DIR
```

```bash
cd setup/infra
```

```bash
gcloud builds submit --project ${PROJECT_ID?} --substitutions=_ACTION=plan
```

```bash
gcloud builds submit --project ${PROJECT_ID?} --substitutions=_ACTION=apply
```

## Deploy Istio Resources

1. From the examples repo:

```bash
(cd manifests && gcloud builds submit --project ${PROJECT_ID?} --substitutions=_REGION=${REGION?})
```

2. Navigate to the url displayed below:

```bash
echo "Open https://monitoring.endpoints.${PROJECT_ID?}.cloud.goog"
```

> You will be authenticated with the cluster IAP or GCIP credential provider and then directed to the Grafana login page.
> You may see SSL errors while the Managed Certificate is provisioned.
