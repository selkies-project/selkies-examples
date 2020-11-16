#!/bin/bash

# Copyright 2020 Google LLC
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

IMAGE_LIST_FILE=$1

gcloud -q auth configure-docker

# Cleanup images
docker images --filter dangling=true -q | xargs -I {} docker rmi {} 2>/dev/null

export IMAGES=()
# Pull all images found in project scoped GCR
if [[ "${PULL_ALL_GCR:-"false"}" == "true" ]]; then
    IFS=$'\r\n' command eval 'GCR_IMAGES=($(gcloud -q container images list --format="value(name)"))'
    for i in ${GCR_IMAGES[*]}; do
        IMAGES+=($i)
    done
fi

# Add additional images from text file to array.
export IMAGES_FROM_FILE=()
if [[ -f "${IMAGE_LIST_FILE?}" ]]; then
    echo "INFO: Reading images from file: ${IMAGE_LIST_FILE?}"
    IFS=$'\r\n' GLOBIGNORE='*' command eval 'export IMAGES_FROM_FILE=($(cat '${IMAGE_LIST_FILE?}'))'
else
    echo "INFO: ${IMAGE_LIST_FILE?} not found, skipping read."
fi

for i in ${IMAGES_FROM_FILE[*]}; do
    echo "Adding image: ${i}"
    IMAGES+=($i)
done

if [[ ${#IMAGES[*]} -eq 0 ]]; then
    echo "ERROR: No images to pull"
    exit 1
fi

echo "INFO: Images to pull: "
echo ${IMAGES[*]} | tr ' ' '\n'

export PROJECT_ID=$(curl -H Metadata-Flavor:Google http://metadata/computeMetadata/v1/project/project-id)

###
# Function to pull image
###
function pullImage() {
    local image=${1/PROJECT_ID/${PROJECT_ID?}}
    echo "INFO: Pulling: ${image}"
    docker pull -q $image > /dev/null
    echo "INFO: Pull complete: ${image}"
}
export -f pullImage

# Pull images in parallel
echo ${IMAGES[*]} | tr ' ' '\n' | xargs -I {} -P$(nproc --ignore=1) bash -c "pullImage {}"

# Cleanup images
docker images --filter dangling=true -q | xargs -I {} docker rmi {} 2>/dev/null

echo "INFO: Done"