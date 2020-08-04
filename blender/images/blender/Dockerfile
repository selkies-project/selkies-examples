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

ARG BASE_IMAGE=gcr.io/my-project/webrtc-gpu-streaming-app-streaming:latest

FROM ${BASE_IMAGE}

# Install blender
RUN \
    sudo apt-get update && sudo apt-get install -y \
    blender

COPY start_blender.sh /
RUN chmod +x /start_blender.sh

ENV EXEC_CMD /start_blender.sh
