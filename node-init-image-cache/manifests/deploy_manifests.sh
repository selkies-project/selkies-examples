#!/bin/bash
gcloud container clusters get-credentials --project="${PROJECT_ID}" --region="${CLOUDSDK_COMPUTE_REGION}" "${CLOUDSDK_CONTAINER_CLUSTER}"
alias kubectl=/builder/kubectl.bash
PD_NAME=$(cat pd_name)
PD_TS=$(cat pd_ts)

items=$(kubectl get pods -n kube-system -l app=pod-broker-image-loader -o jsonpath='{range .items[*]}{@.metadata.ownerReferences[0].name}{","}{@.metadata.labels.pd-name}{","}{@.spec.nodeName}{"\n"}{end}')
for pod in ${items}; do
  IFS=',' read -ra pod_toks <<< "${pod}"
  ds=${pod_toks[0]}
  pd=${pod_toks[1]}
  node=${pod_toks[2]}
  if [[ ${pd} != ${PD_NAME} ]]; then
    # Found pod that is in use by another PD, lock the daemonset used by this pod by patching it's node selector and then label the node.
    echo "INFO: Patching Daemonset ${ds} to lock to existing pods"
    patch_data=$(sed 's/${PD_NAME}/'${pd}'/g' patch-ds.json)
    kubectl patch -n kube-system daemonset ${ds} -p="${patch_data}" --type=json
    kubectl label node "${node}" --overwrite app.broker/cache-pd=${pd}
  fi
done

# Delete old daemonsets if no replicas are scheduled.
items=$(kubectl get daemonset -n kube-system -l app=pod-broker-image-loader -o jsonpath='{range .items[*]}{@.metadata.name}{","}{@.metadata.labels.pd-name}{","}{@.status.currentNumberScheduled}{"\n"}{end}')
for daemonset in ${items}; do
  IFS=',' read -ra ds_toks <<< "${daemonset}"
  ds=${ds_toks[0]}
  pd=${ds_toks[1]}
  count=${ds_toks[2]}
  if [[ ${count} -eq 0 && ${pd} != ${PD_NAME} ]]; then
    kubectl delete ds ${ds} -n kube-system || true
  fi
done

# Delete old PVCs and PVs if no pods are claiming them.
read -ra claimed_pvs <<< $(kubectl get pods -n kube-system -l app=pod-broker-image-loader -o jsonpath='{.items[*].spec.volumes[0].persistentVolumeClaim.claimName}')
read -ra all_pvs <<< $(kubectl get pv -n kube-system -l app=image-cache -o jsonpath='{.items[*].metadata.name}')
for pv in ${all_pvs[@]}; do
  if [[ ! "${claimed_pvs[@]}" =~ "${pv}" && ${pv} != ${PD_NAME} ]]; then
    kubectl delete pv,pvc ${pv} -n kube-system || true
  fi
done

# Remove old reaper cronjob in the kube-system namespace
kubectl delete cronjob -n kube-system -l k8s-app=image-puller-subscription-reaper 2>/dev/null || true

# Remove old reaper cronjob in the pod-broker-system namespace that should have been in the selkies core repo.
kubectl delete cronjob -n pod-broker-system ${DISK_ZONE}-image-puller-subscription-reaper 2>/dev/null || true

sed -i -e 's/${ZONE}/'${DISK_ZONE}'/g' kustomization.yaml

kubectl.1.17 kustomize | \
  sed \
    -e 's/${PROJECT_ID}/'${PROJECT_ID}'/g' \
    -e 's/${PD_NAME}/'${PD_NAME}'/g' \
    -e 's/${TS}/'${PD_TS}'/g' \
    -e 's/${ZONE}/'${DISK_ZONE}'/g' | \
kubectl apply -f -
