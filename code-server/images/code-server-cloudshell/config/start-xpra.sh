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

XPRA_PORT=${XPRA_PORT:-"8080"}

timeout 1 xpra info $XPRA >/dev/null 2>&1
[[ $? -eq 0 ]] && echo "INFO: Xpra is already running at: https://${CODE_SERVER_WEB_PREVIEW_8080}/" && exit 0

if [[ -z "${XPRA_HTML5_DEFAULT_SETTINGS}" ]]; then
  read -r -d '' XPRA_HTML5_DEFAULT_SETTINGS << EOM
floating_menu = true
video = false
sound = false
encoding = jpeg
autohide = true
EOM
  export XPRA_HTML5_DEFAULT_SETTINGS
fi

# Write html5 client default settings
if [[ -n "${XPRA_HTML5_DEFAULT_SETTINGS}" ]]; then
  sudo rm -f /usr/share/xpra/www/default-settings.txt.*
  echo "${XPRA_HTML5_DEFAULT_SETTINGS}" | sudo tee /usr/share/xpra/www/default-settings.txt >/dev/null
fi

mkdir -p ${HOME}/.xpra/logs

xpra start \
  --bind-tcp=0.0.0.0:${XPRA_PORT} \
  --html=on \
  --daemon=yes \
  --no-pulseaudio \
  --log-dir=${HOME}/.xpra/logs \
  --start="xfdesktop --sm-client-disable -A" \
  $@ \
    > ${HOME}/.xpra.log 2>&1

if [[ ! "$@" =~ daemon=no ]]; then
  export XPRA="tcp://127.0.0.1:${XPRA_PORT}"

  echo "INFO: Starting Xpra HTML5 server on port ${XPRA_PORT}"
  until xpra info $XPRA 2>&1 >/dev/null; do sleep 1; done
  echo "INFO: Xpra is running at: https://${CODE_SERVER_WEB_PREVIEW_8080}/"
fi
