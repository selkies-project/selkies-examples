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

[[ $# -ne 2 ]] && echo "USAGE: $0 <src project id> <dest project id>" && exit 1

SRC_PROJECT=$1
DEST_PROJECT=$2
PROJECT_ID=${PROJECT_ID:-${DEST_PROJECT}}

JOB_NAME="${PROJECT_ID?}-selkies-image-copy"

TMP_F=$(tempfile)
function cleanup() {
  rm -f $TMP_F
}
trap cleanup EXIT

cat copy-images-cloudbuild.json | jq \
  --arg src "${SRC_PROJECT}" \
  --arg dest "${DEST_PROJECT}" \
  '.substitutions._SRC_IMAGE_PROJECT=$src | .substitutions._DEST_IMAGE_PROJECT=$dest' \
    > $TMP_F 

gcloud --project ${PROJECT_ID?} scheduler jobs create http ${JOB_NAME} \
  --schedule='0 12 * * *' \
  --uri=https://cloudbuild.googleapis.com/v1/projects/${PROJECT_ID?}/builds \
  --message-body-from-file=${TMP_F} \
  --oauth-service-account-email=${PROJECT_ID?}@appspot.gserviceaccount.com \
  --oauth-token-scope=https://www.googleapis.com/auth/cloud-platform

echo "INFO: Created scheduler job: ${JOB_NAME}"