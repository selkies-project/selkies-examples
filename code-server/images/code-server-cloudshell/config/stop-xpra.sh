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

export XPRA="tcp://127.0.0.1:${XPRA_PORT}"

echo "INFO: Shutting down Xpra"

timeout 1 xpra info $XPRA >/dev/null 2>&1
[[ $? -ne 0 ]] && echo "INFO: Xpra is not running." && exit 0

xpra stop ${XPRA}

echo "INFO: Xpra shutdown complete"