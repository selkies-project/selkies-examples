# Copyright 2020 Google LLC
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

ARG BASE_IMAGE=gcr.io/PROJECT_ID/webrtc-gpu-streaming-app-streaming:focal

FROM ${BASE_IMAGE}

ARG GZDOOM_VERSION=4.5.0
ARG FREEDOOM_VERSION=0.12.1

# Install GZDoom
RUN \
    curl -L https://github.com/coelckers/gzdoom/releases/download/g${GZDOOM_VERSION}/gzdoom_${GZDOOM_VERSION}_amd64.deb > /tmp/gzdoom.deb && \
    apt-get update && \
    gdebi -n /tmp/gzdoom.deb && \
    rm -f /tmp/gzdoom.deb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/games

# Install Freedoom
RUN \
    curl -sfL https://github.com/freedoom/freedoom/releases/download/v${FREEDOOM_VERSION}/freedoom-${FREEDOOM_VERSION}.tar.xz | tar -Jxf - && \
    apt-get update && apt-get install -y \
        make \
        python3-pil \
        deutex \
        asciidoc \
        ruby-asciidoctor-pdf && \
    (cd freedoom-${FREEDOOM_VERSION} && make install) && \
    rm -Rf freedoom-${FREEDOOM_VERSION} && \
    apt-get remove -y make asciidoc ruby-asciidoctor-pdf && \
    rm -rf /var/lib/apt/lists/*

COPY gzdoom.ini /etc/gzdoom.ini

COPY doom-entrypoint.sh /doom-entrypoint.sh
RUN chmod +x /doom-entrypoint.sh
ENV EXEC_CMD /doom-entrypoint.sh