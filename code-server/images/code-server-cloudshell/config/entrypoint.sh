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

echo "INFO: Waiting for docker sidecar"
CERTFILE="/var/run/docker-certs/cert.pem"
until [[ -f ${CERTFILE} ]]; do sleep 1; done
echo "INFO: Docker sidecar is ready, starting unix socket proxy"
sudo /usr/share/code-server/start-docker-unix-proxy.sh

if [[ "${USE_XPRA:-'false'}" == 'true' ]]; then
  # Mimic healthz endpoint
  sudo touch /usr/share/xpra/www/healthz

  # Send xpra logs to stdout
  tail -F ${HOME}/.xpra.log &

  # Start xpra in forground
  while true; do
    /usr/share/code-server/start-xpra.sh --daemon=no
    sleep 1
  done
  killall tail >/dev/null 2>&1
else
  echo "INFO: Starting code-server"
  exec /usr/local/bin/code-server --auth=none --bind-addr=0.0.0.0:3180
fi
