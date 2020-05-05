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

ARG BASE_IMAGE=gcr.io/cloud-solutions-images/webrtc-gpu-streaming-app-streaming:latest

FROM debian:jessie

WORKDIR /tmp
COPY Unigine_Heaven-4.0.run .
RUN sh Unigine_Heaven-4.0.run

FROM ${BASE_IMAGE}

WORKDIR /opt/app

COPY --from=0 /tmp/Unigine_Heaven-4.0/ /opt/app/

WORKDIR /opt/app

ENV ENABLE_WM=false

ENV EXEC_CMD /opt/app/heaven

ENV RESOLUTION 1920x1080