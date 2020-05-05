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

ARG SERVER_BASE_IMAGE=gcr.io/cloud-solutions-images/vdi-supertuxkart-server:latest
ARG BASE_IMAGE=gcr.io/cloud-solutions-images/webrtc-gpu-streaming-app-streaming:latest

FROM ${SERVER_BASE_IMAGE} as stkmatch
FROM ${BASE_IMAGE}

RUN \
    sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    subversion \
    build-essential \
    cmake \
    libbluetooth-dev \
    libcurl4-openssl-dev \
    libenet-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libgl1-mesa-dev \
    libglew-dev \
    libjpeg-dev \
    libogg-dev \
    libopenal-dev \
    libpng-dev \
    libssl-dev \
    libvorbis-dev \
    libxrandr-dev \
    libx11-dev \
    nettle-dev \
    pkg-config \
    zlib1g-dev

WORKDIR /opt/app

RUN \
    git clone https://github.com/supertuxkart/stk-code stk-code && \
    svn co https://svn.code.sf.net/p/supertuxkart/code/stk-assets stk-assets

RUN \
    cd stk-code && \
    git checkout 1.1 && \
    mkdir cmake_build && \
    cd cmake_build && \
    cmake -DBUILD_RECORDER=off -DUSE_WIIUSE=off .. && \
    make -j24

COPY --from=stkmatch /stkmatch /

# Install runtime dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libbluetooth-dev \
    libcurl4-openssl-dev \
    libenet-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libgl1-mesa-dev \
    libglew-dev \
    libjpeg-dev \
    libogg-dev \
    libopenal-dev \
    libpng-dev \
    libssl-dev \
    libvorbis-dev \
    libxrandr-dev \
    libx11-dev \
    nettle-dev \
    zlib1g-dev \
    libxv1 \
    pulseaudio \
    xterm \
    mesa-utils \
    x11-xserver-utils \
    x11-apps \
    feh \
    curl \
    ca-certificates \
    dnsutils \
    redis-server

RUN mkdir -p /tmp/stk-config/
COPY *.xml /tmp/stk-config/

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /opt/app/stk-code/cmake_build/bin

ENV RESOLUTION=1920x1080

ENV EXEC_CMD /start.sh