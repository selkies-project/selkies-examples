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

FROM golang:1.13-alpine as build
RUN apk add -u git
ENV GO111MODULE=on
WORKDIR /go/src/gcp.solutions/guacamole-token
COPY . .
RUN go build cmd/guacamole-token/guacamole_token.go

FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

# Copy build from previous layer
COPY --from=build /go/src/gcp.solutions/guacamole-token/guacamole_token /usr/local/bin/guacamole-token

ENTRYPOINT ["/usr/local/bin/guacamole-token", "-port", "8081"]
