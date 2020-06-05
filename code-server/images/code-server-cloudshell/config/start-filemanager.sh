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

VERSION=2.4.3

CONFIG_DIR=${HOME}/.config/tinyfilemanager
mkdir -p ${CONFIG_DIR}/src

PHP_INI=${CONFIG_DIR}/php.ini
CONFIG_FILE=${CONFIG_DIR}/src/config.php

SRC_URL="https://github.com/prasathmani/tinyfilemanager/archive/${VERSION}.tar.gz"

if [[ ! -f ${CONFIG_DIR}/src/tinyfilemanager.php ]]; then
    curl -sfL "${SRC_URL}" | tar --strip-components=1 -C ${CONFIG_DIR}/src -zxf -
fi

cat - > $PHP_INI <<'EOF'
; Maximum allowed size for uploaded files.
upload_max_filesize = 1024M 

; Must be greater than or equal to upload_max_filesize
post_max_size = 1024M
EOF

cat - > $CONFIG_FILE <<'EOF'
<?php
$use_auth = false;
$root_path = "/data";
?>
EOF

docker run --name tinyfilemanager --rm \
  -p 8000:80 \
  -v ${CONFIG_DIR}/src/:/opt/app/ \
  -v ${PHP_INI}:/etc/php.ini \
  -v ${HOME}:/data \
  -w /opt/app/ \
  --entrypoint=/usr/local/bin/php \
  tigerdockermediocore/tinyfilemanager-docker:latest \
    -S 0.0.0.0:80 -c /etc/php.ini tinyfilemanager.php
    