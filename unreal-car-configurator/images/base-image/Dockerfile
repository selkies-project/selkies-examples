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

FROM ubuntu:19.10

# Use GCE apt servers
ARG GCE_ZONE=us-west1
RUN cp /etc/apt/sources.list /etc/apt/sources.list.orig && \
    sed -i "s/archive.ubuntu.com/${GCE_ZONE}.gce.archive.ubuntu.com/g" /etc/apt/sources.list

# Install base dependencies
RUN apt-get update && apt-get install -y \
        sudo \
        vim \
        emacs \
        curl \
        wget \
        software-properties-common \
        gdebi-core

# Install basic window manager
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xfwm4

# Install Vulkan, OpenGL-ES and GLX libraries.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libvulkan1 \
        vulkan-utils \
        mesa-utils \
        mesa-vulkan-drivers \
        mesa-utils-extra \
        lxrandr \
        libxrandr-dev

# Add i386 architecture
RUN sudo dpkg --add-architecture i386 && \
    sudo apt-get update

# Fix for missing libfaudio0 packages in ubuntu:18.04
RUN wget https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/amd64/libfaudio0_19.07-0~bionic_amd64.deb && \
    wget https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/i386/libfaudio0_19.07-0~bionic_i386.deb && \
    sudo gdebi -n libfaudio0_19.07-0~bionic_amd64.deb && \
    sudo gdebi -n libfaudio0_19.07-0~bionic_i386.deb

# Install wine
RUN sudo apt-add-repository --remove 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Ubuntu_18.10_standard ./' && \
    wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    sudo apt-key add winehq.key && \
    sudo apt-add-repository https://dl.winehq.org/wine-builds/ubuntu/ && \
    sudo apt-get install -y --install-recommends winehq-stable

# Install Vulkan ICD
COPY nvidia_icd.json /usr/share/vulkan/icd.d/

# Install EGL config
RUN mkdir -p /usr/share/glvnd/egl_vendor.d
COPY 10_nvidia.json /usr/share/glvnd/egl_vendor.d/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

# Create app user
RUN groupadd -g 1000 app && \
    useradd -g 1000 -u 1000 app -s /bin/bash && \
    passwd -d app && \
    mkdir -p /home/app && \
    mkdir -p /home/app/.vnc && \
    echo "xsetroot -solid grey" > /home/app/.vnc/xstartup && \
    chmod +x /home/app/.vnc/xstartup && \
    chown 1000:1000 -R /home/app > /dev/null 2>&1 || true

# Grant sudo to user for vulkan init workaround
RUN adduser app sudo

RUN echo "app ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER app
ENV USER app

# Export library path for NVIDIA libs
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib64:/usr/local/nvidia/lib32

# Set the DISPLAY variable.
ENV DISPLAY :0

# Set the PATH
ENV PATH ${PATH}:/usr/local/nvidia/bin:/usr/games

ENV RESOLUTION 1920x1080

ENTRYPOINT ["/entrypoint.sh"]