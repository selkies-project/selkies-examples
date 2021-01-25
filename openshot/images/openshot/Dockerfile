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

ARG BASE_IMAGE=gcr.io/my-project/webrtc-gpu-streaming-app-streaming:focal

FROM ${BASE_IMAGE}

# Install dependencies
RUN \
    sudo apt-get update && sudo apt-get install -y \
        unzip \
        software-properties-common \
        libllvm6.0 \
        xdotool

# Install OpenShot from PPA
RUN \
    sudo add-apt-repository -y ppa:openshot.developers/ppa && \
    sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openshot-qt

COPY start_openshot.sh /
RUN chmod +x /start_openshot.sh

WORKDIR /home/app

COPY *.mp4 ./
ADD http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4 ./
RUN sudo chown app:app *.mp4 && sudo chmod 0644 *.mp4

ENV EXEC_CMD /start_openshot.sh
