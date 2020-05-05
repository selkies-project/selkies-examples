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

# Unzip release zip
FROM alpine:latest

WORKDIR /tmp
COPY xonotic-0.8.2.zip .
RUN  unzip xonotic-0.8.2.zip
RUN chown -R 1000:1000 Xonotic

FROM ${BASE_IMAGE}

COPY --from=0 /tmp/Xonotic /opt/Xonotic

WORKDIR /opt/Xonotic

ENV EXEC_CMD /opt/Xonotic/xonotic-linux-glx.sh
