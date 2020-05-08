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

USERNAME=vdi

PASSWORD=$(gcloud -q secrets versions access 1 --secret ${INSTANCE_NAME?}-password 2>/dev/null || true)

if [[ -n "${PASSWORD}" ]]; then
    echo "INFO: Using password from Secret Manager secret: ${INSTANCE_NAME?}-password"
else
    PASSWORD=$(${GCLOUD} compute reset-windows-password ${INSTANCE_NAME?} --zone ${INSTANCE_ZONE?} --user $USERNAME --format='value(password)')
    # Save password in Secret Manager
    gcloud -q secrets create ${INSTANCE_NAME?}-password --replication-policy=automatic --data-file <(echo -n ${PASSWORD})
fi

echo "INFO: Starting credentials API"
jq --arg u "$USERNAME" --arg p "$(echo -n $PASSWORD | base64)" '.api = {"credential_type": "ephemeral", "username": $u, "password": $p}' <<< '{"api":{}}' > api.json
json-server --port 8080 --host 0.0.0.0 api.json &

while true; do
    echo "INFO: Starting IAP tunnel for RDP to instance"
    ${GCLOUD} compute start-iap-tunnel ${INSTANCE_NAME?} 3389 --zone ${INSTANCE_ZONE?} --local-host-port=0.0.0.0:3389 || true
    sleep 2
done
