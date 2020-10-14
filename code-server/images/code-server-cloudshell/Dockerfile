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

ARG CODE_SERVER_BASE=codercom/code-server:3.6.0
FROM ${CODE_SERVER_BASE} as code-server

FROM gcr.io/cloudshell-images/cloudshell:latest

COPY --from=code-server /usr/lib/code-server /usr/lib/code-server
RUN ln -s /usr/lib/code-server/bin/code-server /usr/local/bin/code-server

# Add Tini
ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 /tini
RUN chmod +x /tini

# Install additional tools
RUN apt-get install -y \
    bsdtar \
	apt-transport-https \
	gdebi-core \
    socat

# Install ffmpeg-xpra
RUN curl -o ffmpeg-xpra.deb -L https://www.xpra.org/dists/stretch/main/binary-amd64/ffmpeg-xpra_4.0-1_amd64.deb && \
    gdebi -n ffmpeg-xpra.deb && \
    rm -f ffmpeg-xpra.deb

# Install xpra, xephyr and xfce4
RUN curl -sfL https://xpra.org/repos/buster/xpra.list | tee /etc/apt/sources.list.d/xpra-beta.list && \
	curl -sfL https://xpra.org/gpg.asc | apt-key add - && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xpra \
        xterm \
        xfce4 \
        xfce4-terminal

# Install mesa software GLX
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        mesa-utils

# Install Chrome browser
RUN curl -sfL https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && \
    curl -sfLO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    sudo gdebi -n google-chrome-stable_current_amd64.deb && \
    sudo ln -s /opt/google/chrome/chrome /usr/local/bin/chrome

# Copy shared config files
WORKDIR /usr/share/code-server
COPY config/* ./

# Download git-prompt to use as default prompt.
RUN curl -sfL -o /usr/share/code-server/git-prompt.sh \
	https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Add user and grant sudo
RUN sed -i 's/:1000:/:2000:/g' /etc/{group,passwd} && \
    groupadd --gid 1000 coder && \
    adduser --uid=1000 --gid=1000 --gecos '' --disabled-password --shell /bin/bash coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

WORKDIR /home/coder/project

RUN chown coder:coder /home/coder -R

USER coder

# Prevent zombie python processes whenever gcloud is run.
RUN gcloud config set disable_usage_reporting true

# Use bash as default shell
ENV SHELL /bin/bash
ENV USER coder
ENV DISPLAY :0

ENTRYPOINT ["/tini", "--", "/usr/share/code-server/entrypoint.sh"]
