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

# Allow container to connect to X11 server.
export DISPLAY=${DISPLAY:-":0"}
echo "Waiting for X11 startup"
until xhost + >/dev/null 2>&1; do sleep 1; done
echo "X11 startup complete"

# Ensure nvidia-modeset and nvidia-uvm modules are loaded.
# This is required to get the nvcodec gstreamer plugin to work.
sudo modprobe nvidia-modeset
sudo modprobe nvidia-uvm

# Stop existing containers
sudo docker kill broker-gce-proxy
sudo docker rm broker-gce-proxy
sudo docker kill webrtc
sudo docker rm webrtc

# Start the web proxy that injects the instance identity token and broker cookie.
CLIENT_ID=$(curl -f -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/broker-client-id)
BROKER_COOKIE=$(curl -f -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/broker-cookie)
BROKER_ENDPOINT=$(curl -f -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/broker-endpoint)
BROKER_PROXY_IMAGE=$(curl -f -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/broker-proxy-image)
WEBRTC_APP_IMAGE=$(curl -f -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/webrtc-app-image)
APP_NAME=$(cut -d'_' -f2 <<< ${BROKER_COOKIE%=*})

sudo docker run --name broker-gce-proxy -d --restart=always \
  --net=host \
  -e CLIENT_ID=${CLIENT_ID?} \
  -e BROKER_COOKIE=${BROKER_COOKIE?} \
  -e BROKER_ENDPOINT=${BROKER_ENDPOINT?} \
  ${BROKER_PROXY_IMAGE?}

# Wait for proxy startup
echo "INFO: Waiting for proxy startup"
until curl --connect-timeout 1 -sf http://localhost:5050/turn/ >/dev/null 2>&1; do sleep 1; done
echo "INFO: Proxy is ready"

# Start the webrtc container
sudo docker run --name webrtc -d --restart=always \
    --privileged \
    --tty \
    --net=host \
    --ipc=host \
    -e GST_DEBUG="*:2" \
    -e LD_LIBRARY_PATH="/usr/local/nvidia/lib64:/usr/local/nvidia/cuda/lib64" \
    -e DISPLAY=":0" \
    -e SIGNALLING_SERVER="ws://127.0.0.1:5050/${APP_NAME?}/signalling/" \
    -e COTURN_AUTH_HEADER_NAME="x-goog-authenticated-user-email" \
    -e COTURN_WEB_URI="http://127.0.0.1:5050/turn/" \
    -e COTURN_WEB_USERNAME="${HOSTNAME}" \
    -e ENABLE_AUDIO="false" \
    -e PULSE_SERVER="/var/run/user/${UID}/pulse/native" \
    -v ${HOME}/.config/pulse:/root/.config/pulse \
    -v /usr/local/nvidia:/usr/local/nvidia \
    -v /usr/bin/nvidia-smi:/usr/bin/nvidia-smi \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /var/run/user/${UID}/pulse:/var/run/user/${UID}/pulse \
    -v /var/run/user/webrtc/appconfig:/var/run/appconfig \
    ${WEBRTC_APP_IMAGE?}
