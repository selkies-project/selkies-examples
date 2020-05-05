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

# Set background
feh -F /opt/app/stk-code/data/gui/icons/logo_slim.png &

SET_WIDTH=1920
SET_HEIGHT=1080
STK_SERVER_MATCH="http://supertuxkart-server.supertuxkart.svc.cluster.local:8080/match"

# Game Config
PLAYER_NAME=${VDI_USER:?env not set}
# remove email domain
PLAYER_NAME=${PLAYER_NAME%@*}
STK_CONFIG_DIR="/home/app/.config/supertuxkart/config-0.10"
mkdir -p "${STK_CONFIG_DIR}"
cp /tmp/stk-config/{input,server_config}.xml "${STK_CONFIG_DIR}/"

sed -e 's/="SuperTuxKart"/="'${PLAYER_NAME}'"/g' \
    /tmp/stk-config/players.xml > "${STK_CONFIG_DIR}/players.xml"

sed -e 's/width=.*/width="'${SET_WIDTH}'"/g' \
    /tmp/stk-config/config.xml > "${STK_CONFIG_DIR}/config.xml"

sed -e 's/height=.*/height="'${SET_HEIGHT}'"/g' \
    /tmp/stk-config/config.xml > "${STK_CONFIG_DIR}/config.xml"

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/app/stk-code/cmake_build/lib/wiiuse/src

echo "Running SuperTuxKart"
while true; do
    cd /opt/app/stk-code/cmake_build/bin
    if [[ "${VDI_singlePlayer:-false}" == "true" ]]; then
        # Single player
        ./supertuxkart --demo-mode=15
    else
        # Wait for server match
        SERVER_MATCH=""
        until [[ -n "${SERVER_MATCH}" ]]; do SERVER_MATCH=$(curl -sf ${STK_SERVER_MATCH}); echo "Waiting for server match at: ${STK_SERVER_MATCH}"; sleep 2; done
        ./supertuxkart --connect-now=${SERVER_MATCH} --auto-connect
    fi
done