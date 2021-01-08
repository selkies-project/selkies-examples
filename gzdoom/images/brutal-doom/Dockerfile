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

ARG BASE_IMAGE=gcr.io/PROJECT_ID/vdi-gzdoom-base:latest

FROM alpine:latest as data
RUN apk add -u unrar
WORKDIR /tmp
COPY doommetallost1.1.3.zip .
RUN unzip doommetallost1.1.3.zip
COPY brutalv21.rar .
RUN unrar x /tmp/brutalv21.rar brutalv21.pk3

FROM ${BASE_IMAGE}

COPY --from=data /tmp/doommetalost1.1.wad /usr/local/share/games/doom/doommetalost1.1.wad
COPY --from=data /tmp/brutalv21.pk3 /usr/local/share/games/doom/brutalv21.pk3
COPY Doom1.wad /usr/local/share/games/doom/Doom1.wad
COPY Doom2.wad /usr/local/share/games/doom/Doom2.wad

ENV EXEC_CMD="/doom-entrypoint.sh /usr/local/share/games/doom/brutalv21.pk3"
