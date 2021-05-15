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

export PD_DIR=$1
export PD_DOCKER_DIR=${PD_DIR}/var/lib/docker
OVERLAY_DEST=$2

[[ ! -d ${PD_DOCKER_DIR} ]] && echo "ERROR: docker directory from persistent disk not found: $PD_DOCKER_DIR" && exit 1

function mountLayer() {
    local src_cache_dir=$1
    local mounts_file=$2
    export cache_id=$(basename $src_cache_dir)
    mapfile -t mounts < "$mounts_file"

    # Bind mount the layer contents to overlay2 directory
    local dest_cache_dir=/var/lib/docker/overlay2/${cache_id}
    if [[ ! ${mounts[@]} =~ "${dest_cache_dir}" ]]; then
        mkdir -p ${dest_cache_dir}/diff
        mount --bind ${src_cache_dir}/diff ${dest_cache_dir}/diff
    fi

    # Copy additonal (mutable) files.
    cp -f ${src_cache_dir}/{link,lower,committed} ${dest_cache_dir}/ 2>/dev/null || true

    # Create symlinks to the cache layer.
    export link_name=$(cat ${src_cache_dir}/link)
    mkdir -p /var/lib/docker/overlay2/l
    [[ ! -L /var/lib/docker/overlay2/l/${link_name} ]] && (cd /var/lib/docker/overlay2/l && ln -sf ../${cache_id}/diff ${link_name})
}
export -f mountLayer

echo "Loading cached image repos..."

JQ=$(command -v jq)
if [[ -z "$JQ" ]]; then
    # Install JQ
    # TODO, run this on builder instance and call from mounted dir
    JQ=/home/kubernetes/bin/jq
    [[ ! -f "${JQ}" ]] && curl -sfL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > ${JQ} && chmod +x ${JQ}
fi

if ! mountpoint -q "/var/lib/docker/image"; then
    # Merge the repositories.json file
    TMP=$(mktemp)
    flock -w 10 -x /var/lib/docker/image/overlay2/repositories.json sh -exc "
    cp /var/lib/docker/image/overlay2/repositories.json /var/lib/docker/image/overlay2/repositories.json.orig;
    ${JQ} -r -c -s '.[0] * .[1]' /var/lib/docker/image/overlay2/repositories.json.orig ${PD_DOCKER_DIR}/image/overlay2/repositories.json > /var/lib/docker/image/overlay2/repositories.json;
    rm -f ${TMP};"

    # Mount overlayfs on top of layerdb
    mkdir -p ${OVERLAY_DEST}/image/{upper,work}
    ! mountpoint -q "/var/lib/docker/image" && mount -t overlay overlay -o lowerdir=/var/lib/docker/image:${PD_DOCKER_DIR}/image,upperdir=${OVERLAY_DEST}/image/upper,workdir=${OVERLAY_DEST}/image/work /var/lib/docker/image

    # Restart docker daemon to re-read repositories.json
    # TODO: find a more graceful way to do this.
    systemctl restart docker
else
    echo "/var/lib/docker/image is already mounted, skipping"
fi

# NOTE, the layer bind mounts must be done after the docker daemon has been restarted.
# A docker daemon restart will clear them.
echo "Loading cached image layers..."

# List all current mounts and cache to file
CURR_MOUNTS=$(mktemp)
findmnt -l -n -o TARGET -S $(mountpoint -d $PD_DIR) | grep /var/lib/docker/overlay2 > $CURR_MOUNTS
export CURR_MOUNTS

# Mount the layer data
time find ${PD_DOCKER_DIR}/overlay2 -mindepth 1 -maxdepth 1 -type d -not -path "${PD_DOCKER_DIR}/overlay2/l" | xargs -I {} -P$(nproc) bash -c "mountLayer {} $CURR_MOUNTS"
rm -f ${CURR_MOUNTS}
