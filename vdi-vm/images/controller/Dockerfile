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

FROM gcr.io/cloud-builders/kubectl as kubectl

FROM google/cloud-sdk:alpine

RUN apk add -u openssl jq npm && \
    npm install -g json-server

# Install kubectl
COPY --from=kubectl /builder/google-cloud-sdk/bin/kubectl /usr/local/bin/kubectl

WORKDIR /run/vdi

# Download gotty
RUN curl -sfL https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz | tar -zxf -

COPY config/* ./

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]