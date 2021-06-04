#!/bin/bash

# Copyright 2021 The Selkies Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export POD_NAME=""
function cleanup() {
    [[ -n "${POD_NAME}" ]] && kubectl delete pod ${POD_NAME} >/dev/null 2>&1 || true
}
trap cleanup EXIT TERM

function _get_default_nfs() {
  kubectl get deployment -n kube-system nfs-client-provisioner -o json | \
    jq -r -c '.spec.template.spec.containers[0].env[] | select(.name | test("NFS_")) | "export \(.name)=\(.value)"'
}

function _get_nfs_info() {
    serverpath=""
    while [[ -z "${serverpath}" ]]; do
        if [[ -n "$NFS_SERVER" ]]; then
          read -p "Enter path to NFS mount in the form of SERVER:PATH ($NFS_SERVER:$NFS_PATH): " input >&2
          [[ -z "${input}" ]] && input="$NFS_SERVER:$NFS_PATH"
        else
          read -p "Enter path to NFS mount in the form of SERVER:PATH : " input >&2
        fi
        IFS=':' read -ra toks <<< "${input}"
        if [[ ${#toks[@]} -ne 2 ]]; then
          echo "Invalid input. Must be in the form of SERVER:PATH" >&2
        else
          serverpath=$input
        fi
    done
    echo "${serverpath}"
}

function kube-nfs-admin() {
    serverpath=$1
    [[ -z "${serverpath}" ]] && eval $(_get_default_nfs)
    [[ -z "${serverpath}" ]] && serverpath=$(_get_nfs_info)

    IFS=':' read -ra toks <<< "${serverpath}"
    nfsserver=${toks[0]}
    nfspath=${toks[1]}
    echo "INFO: Creating pod with NFS mount ${nfsserver}:${nfspath} at /mnt/nfs" >&2

    read -r -d '' SPEC_JSON <<EOF
{
  "apiVersion": "v1",
  "spec": {
    "containers": [{
      "name": "shell",
      "command": ["bash"],
      "image": "google/cloud-sdk:alpine",
      "workingDir": "/mnt/nfs",
      "stdin": true,
      "stdinOnce": true,
      "tty": true,
      "volumeMounts": [{
        "name": "nfs",
        "mountPath": "/mnt/nfs"
      }]
    }],
    "volumes": [{
      "name": "nfs",
      "nfs": {
        "server": "${nfsserver}",
        "path": "${nfspath}"
      }
    }]
  }
}
EOF
    id=$(printf "%x" $((RANDOM + 100000)))
    POD_NAME="nfs-admin-${id}"
    kubectl run -n ${KUBECTL_PLUGINS_CURRENT_NAMESPACE:-default} ${POD_NAME} -i -t --rm --restart=Never --image=debian:latest --overrides="${SPEC_JSON}"
}

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

if [[ -n "${NFS_HOST}" && -n "${NFS_PATH}" ]]; then
  kube-nfs-admin ${NFS_HOST}:${NFS_PATH}
else
  kube-nfs-admin $@
fi