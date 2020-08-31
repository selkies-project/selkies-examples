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

export PD_DOCKER_DIR=$1
OVERLAY_DEST=$2

[[ ! -d ${PD_DOCKER_DIR} ]] && echo "ERROR: docker directory from persistent disk not found: $PD_DOCKER_DIR" && exit 1

function mountLayer() {
    local src_cache_dir=$1
    export cache_id=$(basename $src_cache_dir)

    # Bind mount the layer contents to overlay2 directory
    local dest_cache_dir=/var/lib/docker/overlay2/${cache_id}
    mkdir -p ${dest_cache_dir}
    if ! mountpoint -q "${dest_cache_dir}"; then
        mount --bind ${src_cache_dir} ${dest_cache_dir}
    fi

    # Create symlinks to the cache layer.
    export link_name=$(cat ${src_cache_dir}/link)
    mkdir -p /var/lib/docker/overlay2/l
    [[ ! -L /var/lib/docker/overlay2/l/${link_name} ]] && (cd /var/lib/docker/overlay2/l && ln -sf ../${cache_id}/diff ${link_name})
}
export -f mountLayer

# Mount the layer data
find ${PD_DOCKER_DIR}/overlay2 -mindepth 1 -maxdepth 1 -type d -not -path "${PD_DOCKER_DIR}/overlay2/l" | xargs -I {} -P$(nproc) bash -c "mountLayer {}"

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
    ! mountpoint -q "/var/lib/docker/image" && mount -t overlay overlay -o lowerdir=${PD_DOCKER_DIR}/image:/var/lib/docker/image,upperdir=${OVERLAY_DEST}/image/upper,workdir=${OVERLAY_DEST}/image/work /var/lib/docker/image
else
    echo "/var/lib/docker/image is already mounted, skipping"
fi

# Restart the docker daemon to reload the layer cache.
systemctl restart docker
