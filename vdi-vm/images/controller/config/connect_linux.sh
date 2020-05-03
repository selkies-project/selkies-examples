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

# Fetch VM controller private key from Secret Manager
SSH_KEY_FILE=${HOME}/.ssh/vdi-vm-controller.key
mkdir -p ${HOME}/.ssh
gcloud -q secrets versions access 1 --secret vdi-vm-controller-ssh-key > ${SSH_KEY_FILE}
chmod 0600 ${SSH_KEY_FILE}
chmod 0700 ${HOME}/.ssh

# Derive public key from private key
ssh-keygen -y -f ${SSH_KEY_FILE} > ${SSH_KEY_FILE}.pub

# Add the SSH key to the instance project.
${GCLOUD} compute config-ssh --ssh-key-file=${SSH_KEY_FILE}

function checkInstance() {
    local gotty_port=$1

    # Health check the goTTY port
    local healthy=0
    local attempt=0
    while [[ $attempt -lt 5 ]]; do
        nc -vz localhost $gotty_port >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            ((healthy=healthy+1))
        fi
        ((attempt=attempt+1))
        [[ $healthy -ge 3 ]] && break
        sleep 1
    done
    if [[ $healthy -lt 3 ]]; then
        echo "WARN: GoTTY port is unhealthy" >&2
        return 1
    fi
    return 0
}

while true; do
    echo "INFO: copying scripts to instance"
    $GCLOUD compute scp gotty start_vdi_services.sh vdi@${INSTANCE_NAME?}:/tmp/ --zone ${INSTANCE_ZONE?} --ssh-key-file=${SSH_KEY_FILE} --tunnel-through-iap

    echo "INFO: starting services on instance"
    $GCLOUD compute ssh vdi@${INSTANCE_NAME?} --zone ${INSTANCE_ZONE?} --ssh-key-file=${SSH_KEY_FILE} --tunnel-through-iap --command "bash /tmp/start_vdi_services.sh"

    echo "INFO: creating IAP tunnel for gotty web server"
    ${GCLOUD} compute start-iap-tunnel ${INSTANCE_NAME?} 9000 --zone ${INSTANCE_ZONE?} --local-host-port=0.0.0.0:9000 &

    while checkInstance 9000; do sleep 2; done
done