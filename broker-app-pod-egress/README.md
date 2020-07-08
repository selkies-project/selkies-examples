# Network Policy for filtering Pod Egress

This tutorial shows how to filter HTTP and HTTPS traffic from a specific VDI container through an existing HTTP proxy server.

The request flow from the container looks like this:

    container > squid transparent proxy sidecar > external squid cache peer instance.

Squid is used as a sidecar to enable transparent proxy through an external server. This is useful for traffic filtering and inspection with minimal workload modifications.

A NetworkPolicy is applied to the entire VDI pod. This policy restricts Egress traffic to only the allowed egress CIDRs and allows traffic to the STUN/TURN services that the WebRTC sidecars require.

## Build the squid proxy image

1. Build the images:

```bash
(cd images && gcloud builds submit)
```

## Deploy the proxy VM

1. Set region:

```bash
REGION=us-west1
```

> NOTE: set this to your desired region.

2. (Optional) Create route with priority 900 for the proxy VMs with next hop set to the firewall appliance instance. Note that this instance must be routable from the `broker` VPC.

```bash
FW_INSTANCE_NAME=my-firewall-appliance
FW_INSTANCE_ZONE=us-west1-a
```

```bash
gcloud compute routes create broker-proxy-fw-${REGION?} --network=broker --priority=900 --destination-range=0.0.0.0/0 --tags broker-proxy-${REGION?} --next-hop-instance=${FW_INSTANCE_NAME?} --next-hop-instance-zone=${FW_INSTANCE_ZONE?}
```

> NOTE: This step is optional if you don't have an upstrem firewall appliance.

3. Enable Private Google Access on the target region:

```bash
gcloud compute networks subnets update broker-${REGION} \
  --region ${REGION} \
  --enable-private-ip-google-access
```

3. Create the base infrastructure for the proxy instances:

```bash
(cd infra && gcloud builds submit)
```

4. Create the proxy instance in your desired region:

```bash
(cd infra/proxy && gcloud builds submit --substitutions=_REGION=${REGION})
```

> NOTE: this step can be run again with a different region parameter to deploy additional proxies.

## Deploy the broker app

1. Obtain the IP of the internal load balancer provisioned by Terraform:

```bash
PROXY_IP=$(gcloud compute forwarding-rules list --filter="name~broker-proxy-${REGION}" --format="value(IPAddress)")
```

2. Deploy the BrokerAppConfig that is configured to use the proxy:

```bash
(cd manifests && gcloud builds submit --substitutions=_REGION=${REGION?},_PROXY_CIDR=${PROXY_IP?}/32,_EGRESS_PROXY=${PROXY_IP?}:3128,_PROXY_CACHE_PEER=${PROXY_IP?})
```

3. From the app launcher, launch the "Proxy Egress Desktop" app.

4. From a terminal in the streaming session check the external IP address of the container:

```bash
curl http://ipinfo.io
curl https://ipinfo.io
```

> NOTE: if your firewall appliance already has SSL decryption enabled, you will see a certificate error without the `-k` option.

## Configure container for SSL decryption

1. Export the generated certificate from the firewall appliance and name the file `corppolicy.crt`.

2. Copy the cert to the image build dir:

```bash
cp corppolicy.crt images/proxy-egress-desktop/
```

3. Build image with certificate:

```bash
(cd images/proxy-egress-desktop && gcloud builds submit -t gcr.io/${PROJECT?}/vdi-proxy-egress-desktop:latest)
```

4. Re-deploy the brokerappconfig with updated image:

```bash
gcloud builds submit --substitutions=_REGION=${REGION?},_PROXY_CIDR=${PROXY_IP?}/32,_EGRESS_PROXY=${PROXY_IP?}:3128,_IMAGE=gcr.io/${PROJECT?}/vdi-proxy-egress-desktop
```

5. From the app launcher interface, shutdown and re-launch the "Proxy Egress Desktop" app.

## Configuring Apt to use proxy

1. From the proxy egress desktop session, create the proxy.conf for apt:

```
cat - | sudo tee /etc/apt/apt.conf.d/proxy.conf <<EOF
Acquire::http::Proxy "http://${http_proxy}/";
Acquire::https::Proxy "http://${http_proxy}/";
EOF
```

2. Update the apt cache:

```
sudo apt-get update
```

## Configuring chrome to use firewall appliance SSL cert

1. In the proxy-egress-desktop container, add cert to Chrome Browser:

```
sudo apt install libnss3-tools
```

2. Open Chrome Browser to run it for the first time.

3. Install the certificate to the chrome nssdb:

```
certutil -d sql:$HOME/.pki/nssdb -A -n 'panw' -i  /usr/local/share/ca-certificates/extra/corppolicy.crt -t TCP,TCP,TCP
```

4. Restart the Chrome browser.

5. Test the proxy by visting https://jsonip.com from the Chrome browser

> The external IP address return should be the public IP of the firewall appliance and no SSL errors should be generated.
