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

set -e

# Install jq
apt-get install -qq jq

gcloud -q auth configure-docker

export IMAGES=()
# Pull all images found in project scoped GCR
if [[ "${PULL_ALL_GCR:-"false"}" == "true" ]]; then
    IFS=$'\r\n' command eval 'GCR_IMAGES=($(gcloud -q container images list --format="value(name)"))'
    for i in ${GCR_IMAGES[*]}; do
        IMAGES+=($i)
    done
fi

# Add additional images to array.
for i in $(echo ${ADDITIONAL_IMAGES:-""} | tr ',' '\n'); do
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

###
# Function to build image with single empty layer
###
function buildEmptyImage() {
    [[ -z "$1" || -z "$2" ]] && echo "USAGE: buildEmptyImage <image:tag> <dest tar>" && return 1
    local src=$1
    local dest=$2
    local name=${src/:*/} # remove tag
    local tag="empty"
    local tmp=$(mktemp -d)

    # Fetch image manifest
    local src_config=$(docker inspect $src)

    # Create empty layer.
    # NOTE: the only file in the layer is one containing the sha256sum of the image config to ensure layer ids are unique.
    mkdir -p ${tmp}/diff
    echo "${src_config}" | sha256sum | cut -d' ' -f1 > ${tmp}/diff/sha256_config
    (cd ${tmp}/diff && tar cf ${tmp}/layer.tar .)
    chain_id=$(sha256sum ${tmp}/layer.tar | cut -d' ' -f1)

    # Move the layer.tar into it's layer directory.
    mkdir ${tmp}/${chain_id}
    mv ${tmp}/layer.tar ${tmp}/${chain_id}

    local container_config="$(jq -r -c '.[]|.ContainerConfig' <<< "$src_config")"
    local digest=$(echo "${chain_id} $(sha256sum <<< ${container_config} | cut -d' ' -f1)" | sha256sum | cut -d' ' -f1)

    # Extract info needed for the image config
    jq -r --null-input \
        --arg architecture "$(jq -r -c '.[]|.Architecture' <<< "$src_config")" \
        --slurpfile config <(jq -r -c '.[]|.Config' <<< "$src_config") \
        --arg container "$(jq -r -c '.[]|.Container' <<< "$src_config")" \
        --slurpfile container_config <(jq -r -c '.[]|.ContainerConfig' <<< "$src_config") \
        --arg created "$(jq -r -c '.[]|.Created' <<< "$src_config")" \
        --arg docker_version "$(jq -r -c '.[]|.DockerVersion' <<< "$src_config")" \
        --arg os "$(jq -r -c '.[]|.Os' <<< "$src_config")" \
        --arg diff_id "sha256:${chain_id}" \
        '{architecture: $architecture, config: $config[0], container: $container, container_config: $container_config[0], created: $created, docker_version: $docker_version, history: [], os: $os, rootfs: {type: "layers", diff_ids: [$diff_id]}}' \
    > ${tmp}/${digest}.json

    # Generate manifest.json
    jq -r -c --null-input \
        --arg config "${digest}.json" \
        --arg tag "${name}:${tag}" \
        --arg layer "${chain_id}/layer.tar" \
        '[{Config: $config, RepoTags: [$tag], Layers: [$layer]}]' \
    > ${tmp}/manifest.json
    
    # Generate repositories file.
    jq -r -c --null-input \
        --arg name "${name}" \
        --arg tag "${tag}" \
        --arg digest "${digest}" \
        '{($name): {($tag): $digest}}' \
    > ${tmp}/repositories

    (cd $tmp && tar -cf "$dest" .)
}

# Create directory to store empty image tarballs
DEST_DIR="/mnt/empty-images"
rm -rf $DEST_DIR
mkdir -p $DEST_DIR

# Pull images in parallel
echo ${IMAGES[*]} | tr ' ' '\n' | xargs -I {} -P$(nproc) bash -c "pullImage {}"

# Build local layer DB to map layer ids to overlay2 diff dirs
echo "Building layerdb from /var/lib/docker/image/overlay2/..."
declare -A LAYERDB
for f in /var/lib/docker/image/overlay2/layerdb/sha256/*/diff; do
    layer_id=$(cat "$f")
    cache_id=$(cat $(dirname $f)/cache-id)
    # Using symlinks to reduce length of mount command arguments.
    diff_link="l/$(cat "/var/lib/docker/overlay2/${cache_id}/link")"
    LAYERDB[$layer_id]=$diff_link
done
export LAYERDB

###
# Function to lookup layer links in layerdb
# Note, uses exported LAYERDB
###
function getUpperDirs() {
    local image=$1
    # Find upper layer directories from layer db.
    # NOTE: that the layers list is reversed to make sure the mount paths are in the right order.
    # NOTE: some images have repating layers, so only uniq layers are used (using unix stable uniq function rather than jq unstable operation).
    for layer_id in $(docker inspect $image | jq -r '.[] | .RootFS.Layers | reverse | .[]' | uniq); do
        echo -n "${LAYERDB[$layer_id]} "
    done
}

###
# Build empty image tarballs for all images
###
for i in ${IMAGES[*]} ; do
    image=${i/PROJECT_ID/${PROJECT_ID?}}
    IMAGE_BASE=$(basename ${image/:*/})
    EMPTY_IMAGE_TAR="${DEST_DIR}/${IMAGE_BASE}.tar"
    buildEmptyImage "${image}" "${EMPTY_IMAGE_TAR}"

    # Find all upper dir symlinks and format them as colon separated for overlayfs mount arg.
    upper_dirs=$(getUpperDirs $image | tr ' ' ':')
    
    # Remove trailing colon and save to layers file.
    echo "${upper_dirs::-1}" > ${EMPTY_IMAGE_TAR}.layers

    echo "Saved empty image tar: $EMPTY_IMAGE_TAR"
done

echo "INFO: Done"