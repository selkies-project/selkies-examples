#!/bin/bash
mkdir -p ${HOME}/.xpra/logs

xpra start --bind-tcp=0.0.0.0:8080 --start=xterm --html=on --daemon=yes --no-pulseaudio --min-quality=50 --min-speed=50 --log-dir=${HOME}/.xpra/logs