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

function logInfo() {
  echo "INFO ($(date)): $@" >&2
}

function logDebug() {
  echo "DEBUG ($(date)): $@" >&2
}

function watchLogs() {
  tail -F /run/guacamole/guacd.log | while read line; do
    ts=$(date)
    #logDebug "$line"
    if [[ "${line}" =~ "Internal RDP client disconnected" ]]; then
      logInfo "idle started, timeout in ${WATCHDOG_TIMEOUT} seconds."
      touch /run/guacamole/idle
    fi
    if [[ "${line}" =~ "RDPDR user logged on" ]]; then
      logInfo "idle ended"
      rm -f /run/guacamole/idle
    fi
  done
}

function startIdle() {
  local count=0
  while [[ count -lt ${WATCHDOG_TIMEOUT} ]]; do
    if [[ -f /run/guacamole/idle ]]; then
      ((count=count+1))
      sleep 1
    else
      # stroke the watchdog
      count=0
      sleep 1
      continue
    fi
  done
  logInfo "watchdog timeout"
}

logInfo "idle watchdog started, timeout: ${WATCHDOG_TIMEOUT?}"

touch /run/guacamole/idle
watchLogs &
startIdle

# Run shutdown script
/idle_shutdown.sh