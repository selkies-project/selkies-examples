#!/bin/bash

# Copyright 2021 The Selkies Authors
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

/usr/bin/openshot-qt &
PID=$!

sleep 3

# Make window fullscreen after starting
until xdotool search --name OpenShot >/dev/null; do sleep 1; done
xdotool windowactivate $(xdotool search --class OpenShot |tail -1)
xdotool key F11

wait $PID
