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
set -x

# Install docker engine
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# The container image is not driver specific and requires that the NVIDIA
# libraries are present at runtime. Create directory on host containing
# the local NVIDIA libraries that will be mounted to the container at runtime.
mkdir -p /usr/local/nvidia/lib64

# Copy NVIDIA libraries to /usr/local/nvidia/lib64/
NVIDIA_LIB_DIR=$(dirname $(ldconfig -p | grep libnvidia-encode.so | grep x86-64 | tr ' ' '\n' | grep / | tail -1))
if [[ ! -d "${NVIDIA_LIB_DIR}" ]]; then
    echo "ERROR: libnvidia-encode.so not found in library path, make sure the NVIDIA driver is installed."
    exit 1
fi
rsync -ra ${NVIDIA_LIB_DIR}/{lib*nv*,lib*cuda*,vdpau} /usr/local/nvidia/lib64/

# Install CUDA libraries
# NOTE the cuda package version must match the cuda driver version from the nvidia-smi output.
apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
curl -LO http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.2.89-1_amd64.deb
dpkg -i cuda-repo-ubuntu1804_10.2.89-1_amd64.deb
apt-get update
apt-get install -y cuda-nvrtc-dev-10-2
CUDA_LIB_DIR=/usr/local/nvidia/cuda/lib64
mkdir -p ${CUDA_LIB_DIR}
rsync -ra /usr/local/cuda-10.2/lib64/* ${CUDA_LIB_DIR}

# Pull docker images
gcloud -q auth configure-docker
docker pull ${BROKER_PROXY_IMAGE?}
docker pull ${GST_WEBRTC_IMAGE?}
