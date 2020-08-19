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

apt-get update

# Install the XFCE linux desktop environment and terminal emulator:
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xubuntu-desktop \
    terminator \
    gdebi-core

# Install the Chrome browser
curl -sfLO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    sudo gdebi -n google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# Disable error reporting dialog popups
sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

# Install NVIDIA driver
dpkg --add-architecture i386
apt-get update
apt-get install -y nvidia-driver-440 libnvidia-gl-440 libnvidia-gl-440:i386
apt-get install -y libvulkan1 libvulkan1:i386 vulkan-utils
nvidia-xconfig

# Set default boot to multi-user mode, to disable automatic startup of the X server
systemctl set-default multi-user.target

# Patch Xwrapper to allow users to run X servers.
sed -i 's/allowed_users=.*/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Disable screen lock and screensaver
cat - | sudo tee /usr/share/glib-2.0/schemas/90_ubuntu-settings.gschema.override <<EOF
[org.gnome.desktop.screensaver]
lock-enabled = false
[org.gnome.settings-daemon.plugins.power]
idle-dim = false
EOF
