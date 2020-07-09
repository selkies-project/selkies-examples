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

FROM alpine:3.9 as extract

WORKDIR /opt/app
ADD https://github.com/coelckers/gzdoom/releases/download/g4.4.2/gzdoom-4-4-2-Windows-64bit.zip .
ADD https://github.com/freedoom/freedoom/releases/download/v0.12.1/freedoom-0.12.1.zip .

RUN ls *.zip | xargs -I {} unzip {} && \
    mv freedoom*/*.wad ./ && \
    rm -Rf freedoom-* *.zip && \
    chown 1000:1000 * -R

FROM ${BASE_IMAGE}

WORKDIR /opt/app

COPY --from=extract /opt/app .

# Set APP_PATH to tell base image entrypoint which program to run.
ENV APP_PATH /opt/app/gzdoom.exe