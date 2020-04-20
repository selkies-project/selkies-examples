#!/bin/bash

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

set -e

cd /tmp

curl -fL -o cloudcode.vsix.gz https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GoogleCloudTools/vsextensions/cloudcode/1.2.1/vspackage && \
    gunzip cloudcode.vsix.gz && \
    code-server --install-extension cloudcode.vsix && \
    rm cloudcode.vsix

echo "Reload your browser window to finish installing Cloud Code"