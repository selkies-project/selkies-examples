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

gcloud --project ${PROJECT_ID?} scheduler jobs create http ${PROJECT_ID?}-run-selkies-image-build \
  --schedule='0 12 * * *' \
  --uri=https://cloudbuild.googleapis.com/v1/projects/${PROJECT_ID?}/builds \
  --message-body-from-file=build-images-cloudbuild.json \
  --oauth-service-account-email=${PROJECT_ID?}@appspot.gserviceaccount.com \
  --oauth-token-scope=https://www.googleapis.com/auth/cloud-platform