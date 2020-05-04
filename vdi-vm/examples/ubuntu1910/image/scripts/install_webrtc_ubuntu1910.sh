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

# Use GCE apt servers
GCE_ZONE=$(curl -H Metadata-Flavor:Google http://metadata/computeMetadata/v1/instance/zone | cut -d/ -f4)
GCE_REGION=${GCE_ZONE%-*}
cp /etc/apt/sources.list /etc/apt/sources.list.orig && \
    sed -i "s/archive.ubuntu.com/${GCE_REGION}.gce.archive.ubuntu.com/g" /etc/apt/sources.list

# Install google cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update && apt-get install -y google-cloud-sdk

# Install docker engine
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install gcp docker credential helper
gcloud -q auth configure-docker

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
docker pull ${BROKER_PROXY_IMAGE?}
docker pull ${GST_WEBRTC_IMAGE?}
