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

ARG BASE_IMAGE=gcr.io/my-project/webrtc-gpu-streaming-app-streaming:focal-cuda

FROM ${BASE_IMAGE}

# Install dependencies
RUN \
    sudo apt-get update && sudo apt-get install -y \
        unzip \
        software-properties-common \
        libllvm6.0

# Install Blender 2.9x with all bells and whistles.
# use this PPA until version 2.9x is in upstream apt repos.
# https://launchpad.net/~thomas-schiex/+archive/ubuntu/blender
RUN \
    sudo add-apt-repository -y ppa:thomas-schiex/blender && \
    sudo apt-get update && \
    sudo apt-get install -y blender

# Add car demo
RUN \
    cd /home/app && \
    curl -LO https://download.blender.org/demo/test/BMW27_2.blend.zip && \
    unzip BMW27_2.blend.zip && \
    rm BMW27_2.blend.zip && \
    chown -R app:app /home/app/bmw27

# Cache CUDA kernel
# Note only need this pre-2.9x
#RUN \
#    mkdir -p /home/app/.cache/cycles/kernels && \
#    nvcc \
#        -arch=sm_75 \
#        --cubin "/usr/share/blender/scripts/addons/cycles/source/kernel/kernels/cuda/kernel.cu" \
#        -o "/home/app/.cache/cycles/kernels/cycles_kernel_sm75_673C3180FADE8EDF0E80E61994C4DC92.cubin" \
#        -m64 \
#        --ptxas-options="-v" \
#        --use_fast_math \
#        -DNVCC -I"/usr/share/blender/scripts/addons/cycles/source" && \
#    mkdir -p /opt/blender/cache/cycles/kernels && \
#    mv /home/app/.cache/cycles/kernels/* /opt/blender/cache/cycles/kernels/ && \
#    chown -R app:app /home/app/.cache && \
#    chmod -R ugo+r /opt/blender/cache/cycles/kernels/

COPY start_blender.sh /
RUN chmod +x /start_blender.sh

WORKDIR /home/app

ENV EXEC_CMD /start_blender.sh /home/app/bmw27/bmw27_gpu.blend
