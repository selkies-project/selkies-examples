#!/bin/bash

set -e

cd /tmp

curl -fL -o cloudcode.vsix.gz https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GoogleCloudTools/vsextensions/cloudcode/1.2.1/vspackage && \
    gunzip cloudcode.vsix.gz && \
    code-server --install-extension cloudcode.vsix && \
    rm cloudcode.vsix

echo "Reload your browser window to finish installing Cloud Code"