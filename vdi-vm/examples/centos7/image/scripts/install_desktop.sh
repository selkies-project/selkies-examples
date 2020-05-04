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

# Install base packages
yum -y update
yum -y groupinstall "Development Tools" "X Window System"
yum -y install kernel-devel dkms

# Install NVIDIA GRID driver
gsutil cp gs://nvidia-drivers-us-public/GRID/GRID9.1/NVIDIA-Linux-x86_64-430.46-grid.run /tmp/
sh /tmp/NVIDIA-Linux-x86_64-430.46-grid.run \
  --dkms \
  --silent \
  --no-questions \
  --ui=none \
  --install-libglvnd

# Install desktop
yum -y groupinstall "Server with GUI" "Fonts"

# Set default boot to multi-user mode, to disable automatic startup of the X server
systemctl set-default multi-user.target

# Configure X11 for NVIDIA
nvidia-xconfig

# Install the Cromium browser
yum -y install chromium
