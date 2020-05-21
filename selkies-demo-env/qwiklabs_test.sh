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

set -e

PROJECT_ID=$(gcloud config get-value project)
ACCOUNT=$(gcloud config get-value account 2>/dev/null)

LAUNCHER_BRANCH="${LAUNCHER_BRANCH:-v1.0.0}"
WEBRTC_BRANCH="${WEBRTC_BRANCH:-v1.4.0}"
EXAMPLES_BRANCH="${EXAMPLES_BRANCH:-master}"
SRC_IMAGE_PROJECT="${SRC_IMAGE_PROJECT:-$PROJECT_ID}"

TS=$(date +%s)

TMP="qwiklabs_test-${TS}.yaml"
cleanup() {
    [[ ! -s key.json ]] && rm -f key.json
    rm -f $TMP
}
trap cleanup EXIT

if [[ ! -f key.json ]]; then
  SA_EMAIL=${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com
  if [[ "$(gcloud -q iam service-accounts list --filter=name~${PROJECT_ID?}@${PROJECT_ID?}.iam.gserviceaccount.com  --format='value(email)')" == "" ]]; then
    echo "INFO: Creating service account: ${SA_EMAIL}"
    gcloud -q --project ${PROJECT_ID?} iam service-accounts create ${PROJECT_ID?} --display-name "project owner"
    gcloud -q projects add-iam-policy-binding ${PROJECT_ID?} --member serviceAccount:${SA_EMAIL?} --role roles/owner
    gcloud -q projects add-iam-policy-binding ${PROJECT_ID?} --member serviceAccount:${SA_EMAIL?} --role roles/resourcemanager.projectIamAdmin
  fi
  gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL
fi

KEY=$(printf "%s\n" "$(jq -rc '.' key.json)")

cat - > $TMP <<EOF
imports:
  - path: qwiklabs.jinja
  - path: templates/build-vm-images.jinja
    name: build-vm-images.jinja
  - path: templates/cleanup-sub-builds.jinja
    name: cleanup-sub-builds.jinja
  - path: templates/code-server-infra.jinja
    name: code-server-infra.jinja
  - path: templates/copy-gcr-images.jinja
    name: copy-gcr-images.jinja
  - path: templates/deploy-app-launcher.jinja
    name: deploy-app-launcher.jinja
  - path: templates/deploy-apps.jinja
    name: deploy-apps.jinja
  - path: templates/elevate-ql-cb-permissions.jinja
    name: elevate-ql-cb-permissions.jinja
  - path: templates/selkies-services.jinja
    name: selkies-services.jinja
  - path: templates/vdi-vm-infra.jinja
    name: vdi-vm-infra.jinja
  - path: templates/wait-for-iap.jinja
    name: wait-for-iap.jinja

resources:
  - name: qwiklabs
    type: qwiklabs.jinja
    properties:
      userName: ""
      launcherUser: "${ACCOUNT?}"
      region: "us-west1"
      zone: "us-west1-a"
      launcher-branch: "${LAUNCHER_BRANCH?}"
      webrtc-branch: "${WEBRTC_BRANCH?}"
      examples-branch: "${EXAMPLES_BRANCH?}"
      src-image-project: "${SRC_IMAGE_PROJECT?}"
      keyFile: '${KEY?}'
EOF

gcloud deployment-manager deployments create --config ${TMP} ql-test-${TS} $@
