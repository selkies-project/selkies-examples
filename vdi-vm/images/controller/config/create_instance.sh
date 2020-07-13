#!/bin/bash

# Copyright 2019 Google LLC
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

GCLOUD="gcloud -q --project ${INSTANCE_PROJECT?}"            

STATUS=$(${GCLOUD} compute instances list --filter=name~${INSTANCE_NAME?} --format='value(status)')

if [[ -z "${STATUS}" ]]; then
    echo "INFO: Creating instance"

    EXTRA_ARGS=""

    # Check for user persistent disk, if found, replace boot disk.
    DISK_NAME="${INSTANCE_NAME?}-persist"
    if [[ -n "$(${GCLOUD} compute disks list --filter=name~${DISK_NAME?} --format='value(name)')" ]]; then
        echo "INFO: Found user persist disk, creating instance with attached disk"
        EXTRA_ARGS="${EXTRA_ARGS} --disk=name=${DISK_NAME},auto-delete=no,boot=yes"
    fi
    
    ${GCLOUD} compute instances create ${INSTANCE_NAME?} \
        --zone ${INSTANCE_ZONE?} \
        --source-instance-template ${INSTANCE_TEMPLATE?} ${EXTRA_ARGS}
fi

# Fetch broker oauth client ID from Secret Manager
CLIENT_ID=$(gcloud -q secrets versions access 1 --secret broker-oauth2-client-id)
BROKER_ENDPOINT="https://${BROKER_DOMAIN?}"

# Add metadata
echo "INFO: Setting instance metadata"
${GCLOUD} compute instances add-metadata ${INSTANCE_NAME?} \
    --zone ${INSTANCE_ZONE?} \
    --metadata vdi-user=${VDI_USER?},broker-cookie=broker_${APP_NAME?}=${BROKER_COOKIE?},broker-client-id=${CLIENT_ID?},broker-endpoint=${BROKER_ENDPOINT?},broker-proxy-image=${VDI_BROKER_PROXY_IMAGE?},webrtc-app-image=${VDI_WEBRTC_APP_IMAGE?},webrtc-idle-timeout=${WATCHDOG_TIMEOUT?}

if [[ "${STATUS}" == "TERMINATED" ]]; then
    # Check for user persistent disk, if found, swap out boot disk.
    DISK_NAME="${INSTANCE_NAME?}-persist"
    if [[ -n "$(${GCLOUD} compute disks list --filter=name~${DISK_NAME?} --format='value(name)')" ]]; then
        echo "INFO: Found user persistent disk: ${DISK_NAME?}"
        CURR_DISK=$(${GCLOUD} compute instances describe ${INSTANCE_NAME?} --format='value(disks[0].name)'
        if [[ "${CURR_DISK?}" != "${DISK_NAME?}" ]]; then
            echo "INFO: Attaching user persistent disk to instance"
            ${GCLOUD} compute instances detach-disk ${INSTANCE_NAME?}
            ${GCLOUD} compute instances attach-disk ${INSTANCE_NAME?} --name=${DISK_NAME?} --boot
        fi
    fi

    echo "INFO: Starting instance"
    ${GCLOUD} compute instances start ${INSTANCE_NAME?} --zone ${INSTANCE_ZONE?}
fi

while [[ "$(${GCLOUD} compute instances list --filter=name~${INSTANCE_NAME?} --format='value(status)')" != "RUNNING" ]]; do
    sleep 2
done
echo "INFO: Instance is running"

READY=""
while [[ -z "${READY}" ]]; do
    if [[ "${INSTANCE_OS?}" == "windows" ]]; then
        READY=$(${GCLOUD} compute instances get-serial-port-output ${INSTANCE_NAME?} --zone ${INSTANCE_ZONE?} --port 1 2>&1 | grep "GCEGuestAgent: GCE Agent Started")
    elif [[ "${INSTANCE_OS?}" == "linux" ]]; then
        READY=$(${GCLOUD} compute instances get-serial-port-output ${INSTANCE_NAME?} --zone ${INSTANCE_ZONE?} --port 1 2>&1 | grep "login: ")
    else
        echo "ERROR: Unsupported instance OS: ${INSTANCE_OS?}"
    fi
    sleep 2
done
echo "INFO: Instance is ready"
