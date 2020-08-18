## Multiple Network Interfaces Example

## Description

Creates secondary network interface on pods to support applications that require broadcast networking and isolated networks.

## Dependencies

- App Launcher: [v1.0.0+](https://github.com/GoogleCloudPlatform/solutions-k8s-stateful-workload-operator/tree/v1.0.0)
- WebRTC Streaming Stack: [v1.4.0+](https://github.com/GoogleCloudPlatform/solutions-webrtc-gpu-streaming/tree/v1.4.0) (images only)

## Features

- Per-application network isolation by subnet using [Weave](https://github.com/weaveworks/weave) multi-host overlay networking.
- Primary network interface still uses Calico and supports NetworkPolicy.
- Configurable CNI network config using [Multus](https://github.com/intel/multus-cni) and the NetworkAttachmentDefinition spec.

## Tutorials

This tutorial will guide you through installing the CNI components and enabling the feature in the BrokerAppConfig.

## Pre-requisites

This tutorial requires that you have already deployed the Kubernetes App Launcher Operator in your GKE cluster.

If you have not already deployed the operator, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/selkies&cloudshell_git_branch=v1.0.0&cloudshell_tutorial=setup/README.md)

This tutorial requires that you have deployed the WebRTC streaming app launcher stack to the cluster.

If you have not installed the WebRTC stack, follow this Cloud Shell tutorial to do so:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/selkies-vdi&cloudshell_git_branch=v1.0.0&&cloudshell_tutorial=tutorials/gke/00_Setup.md).

## Platform verification

3. Obtain cluster credentials:

```bash
REGION=us-west1
```

> NOTE: change this to the region of your cluster.

```bash
gcloud --project ${PROJECT_ID?} container clusters get-credentials broker-${REGION?} --region ${REGION?}
```

2. Verify that the WebRTC streaming manifest bundle is present:

```bash
kubectl get configmap webrtc-gpu-streaming-manifests-1.4.0 -n pod-broker-system
```

## Install CNI components

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```bash
export PROJECT_ID=YOUR_PROJECT
```

```bash
gcloud config set project ${PROJECT_ID?}
```

2. Install the CNI components to your cluster using Cloud Build:

```bash
(cd manifests/cni && gcloud builds submit --project ${PROJECT_ID?} --substitutions=_REGION=${REGION?})
```

3. Verify weave is installed and working:

```bash
WEAVE_POD=$(kubectl get pod -n kube-system -l name=weave-net -o jsonpath='{.items[0].metadata.name}')
```

```bash
kubectl wait pod $WEAVE_POD --for=condition=Ready -n kube-system --timeout=300s
```

```bash
kubectl exec -c weave -it ${WEAVE_POD?} -n kube-system -- /home/weave/weave --local status
```

> Verify that Status is `ready` and that the number of `Peers` is equal to the number of nodes in your cluster.

## Install common multi-nic app

1. Create the NetworkAttachmentDefinition with the Weave config for the app isolated subnet:

```bash
kubectl apply -n default -f manifests/app-common/weave-app-net-attach-def.yaml
```

> NOTE: This is a namespace scoped resource, the VDI app will deploy to a different namespace but will have the same `subnet` as defined in the `spec.config` JSON.

2. Create the NetworkPolicy to deny all traffic on the primary interface:

```bash
kubectl apply -n default -f manifests/app-common/multi-nic-app-networkpolicy.yaml
```

3. Deploy a pod to the default namespace that will run in the same isolated subnet as the VDI pod:

```bash
kubectl apply -n default -f manifests/app-common/multi-nic-app-deploy.yaml
```

> NOTE: if the pod does not start, verify that there are no errors in the output of `kubectl describe`

4. Verify the pod has a secondary interface in the given CIDR range of `10.32.20.0/24`:

```bash
POD=$(kubectl get pod -n default -l app=multi-nic-app -o jsonpath='{.items[0].metadata.name}')
```

```bash
kubectl exec -it -n default $POD -- ifconfig
```

> You should see the output of `ifconfig` showing multiple interfaces, `eth0` with a pod CIDR range IP, and `net1` with the weave CIDR range.

> Make note of the ip address on the net1 interface for later use.

## Install BrokerAppConfig for multi-nic app

1. Deploy the BrokerAppConfig with Cloud Build:

```bash
(cd manifests/brokerapp && gcloud builds submit --project ${PROJECT_ID?} --substitutions=_REGION=${REGION?})
```

## Verify connectivity between apps over Weave network.

1. Launch the Multi NIC App from the App Launcher interface.

> NOTE: After the Xpra interface opens, you should see a xfce4-terminal.

2. Verify the pod has a network interface `net1` with an IP in the app CIDR range.

```bash
ifconfig net1
```

3. Verify you can ping the other common app deployed earlier using its net1 IP.
4. Verify that you __cannot__ ping the common app using its eth0 IP, because of the NetworkPolicy deployed earlier.
5. Verify that you can traceroute the net1 IP of the common app and that there are no hops (direct link)
6. Verify that the output of the `arp` command shows that the common apps IP resolves to a real MAC address and not `ee:ee:ee:ee:ee:ee` (the calico network proxy_arp address).