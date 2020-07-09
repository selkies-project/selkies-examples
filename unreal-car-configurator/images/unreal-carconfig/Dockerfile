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

ARG BASE_IMAGE=gcr.io/PROJECT_ID/vdi-proton-app:latest

# Unpack the zip file in multi-stage build.
FROM alpine:3.9 as extract
RUN apk add -u unzip
WORKDIR /tmp
COPY CarconfiguratorV2.2.zip .
RUN unzip CarconfiguratorV2.2.zip && \
    chown 1000:1000 CarconfiguratorV2.2 -R 

# Copy unpacked contents to final image
FROM ${BASE_IMAGE}

RUN mkdir -p /home/app/Downloads/CarconfiguratorV2.2 && \
    chown app:app /home/app/Downloads/CarconfiguratorV2.2

WORKDIR /opt/app/CarconfiguratorV2.2
COPY --from=extract /tmp/CarconfiguratorV2.2 .

# Set APP_PATH to tell base image entrypoint which program to run.
ENV APP_PATH /opt/app/CarconfiguratorV2.2/WindowsNoEditor/Carfigurator.exe

# Set default resolution, configured by the entrypoint script in the base image.
ENV RESOLUTION=1920x1080

ENV ENABLE_WM=false
