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

cleanup() {
    set +e
    kill $(pgrep -f http-proxy) 2>/dev/null
    docker kill guacamole-token guacamole-lite guacd web-dev windows-api 2>/dev/null
    docker rm guacamole-token guacamole-lite guacd web-dev windows-api 2>/dev/null
}
trap cleanup SIGKILL SIGTERM EXIT

PROJECT_ID=$(gcloud config get-value project)
GUACD_SECRET_KEY=${GUACD_SECRET_KEY:-$(openssl rand -hex 16)}

# docker interface IP, this is used by the guacd container to reach back to the 3389 tunnel on the host
DOCKER_IP=$(ifconfig docker0 | awk '/inet / {print $2}')

# Start tunnel to RDP instance
docker pull gcr.io/${PROJECT_ID?}/vdi-vm-controller:latest
docker run -d --name windows-api --rm --entrypoint=/run/vdi/connect_windows.sh \
  -v $HOME/.config/gcloud:/root/.config/gcloud \
  -p 8083:8080 \
  -p 3389:3389 \
  -e INSTANCE_PROJECT=${RDP_INSTANCE_PROJECT:-$PROJECT_ID} \
  -e INSTANCE_NAME=${RDP_INSTANCE?} \
  -e INSTANCE_ZONE=${RDP_INSTANCE_ZONE?} \
  gcr.io/${PROJECT_ID?}/vdi-vm-controller:latest

# Install node dependencies
npm install

# Start http-proxy
./node_modules/.bin/http-proxy -v \
  --hostname 0.0.0.0 --port 8000 \
  /token=localhost:8081 \
    -H "x-guacd-conn-type: rdp" \
    -H "x-guacd-setting-hostname: ${DOCKER_IP?}" \
    -H "x-guacd-setting-port: 3389" \
    -H "x-guacd-setting-security: any" \
    -H "x-guacd-setting-ignore-cert: true" \
    -H "x-guacd-setting-enable-drive: false" \
    -H "x-guacd-setting-create-drive-path: false" \
  /api=localhost:8083/api \
  /=localhost:8082 \
  /sockjs-node/=localhost/sockjs-node/:8000 &

# Start dev web server
docker run -d --name web-dev --rm -p 8082:80 -v ${PWD}/src:/usr/share/nginx/html -v ${PWD}/config/default.conf:/etc/nginx/conf.d/default.conf nginx:alpine

# Pull latest images
docker pull gcr.io/${PROJECT_ID?}/vdi-vm-guacamole-lite-token:latest
docker pull gcr.io/${PROJECT_ID?}/vdi-vm-guacamole-lite:latest

# Start the token service container.
WSS_HOSTPATH=${WSS_HOSTPATH:-"wss://${CODE_SERVER_WEB_PREVIEW_3000?}/ws"}
docker run -d --name guacamole-token --rm -p 8081:8081 -e GUACD_SECRET_KEY="${GUACD_SECRET_KEY}" -e WSS_HOSTPATH=${WSS_HOSTPATH?} gcr.io/${PROJECT_ID?}/vdi-vm-guacamole-lite-token:latest

# Start guacd container
docker run -d --name guacd --rm docker.io/guacamole/guacd:1.1.0

# Start guacamole-lite server
docker run -d --name guacamole-lite --rm -p 3000:8080 --link guacd:guacd -e GUACD_HOST=guacd -e GUACD_SECRET_KEY="${GUACD_SECRET_KEY}" gcr.io/${PROJECT_ID?}/vdi-vm-guacamole-lite:latest

echo "INFO: Open https://${CODE_SERVER_WEB_PREVIEW_3000} first to store auth cookie"
echo "INFO: Then, open https://${CODE_SERVER_WEB_PREVIEW_8000}"
(while true;do sleep 86400; done)