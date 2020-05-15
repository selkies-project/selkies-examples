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

echo "INFO: waiting for workload identity"
while true; do
    gcloud -q auth list --format='value(account)' 2>/dev/null
    [[ $? -eq 0 ]] && break
    sleep 2
done
echo "INFO: workload identity is ready"

touch /tmp/alive

bash create_instance.sh

if [[ "${INSTANCE_OS?}" == "windows" ]]; then
    bash connect_windows.sh
elif [[ "${INSTANCE_OS?}" == "linux" ]]; then
    bash connect_linux.sh
else
    echo "ERROR: Unsupported OS: ${INSTANCE_OS?}"
    while true; do sleep 86400; done
fi
