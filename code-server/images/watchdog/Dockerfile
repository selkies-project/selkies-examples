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

FROM golang:1.15-alpine as build
RUN apk add --no-cache -u git
ENV GO111MODULE=on
WORKDIR /go/src/selkies.io/watchdog
COPY *.go .
RUN go build -o /code_server_watchdog main.go

FROM alpine:3.5

COPY --from=build /code_server_watchdog /

RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D -g '' app

USER app

ENTRYPOINT ["/code_server_watchdog"]