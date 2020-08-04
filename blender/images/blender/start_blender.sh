#!/bin/sh

# Disable window manager ALT+LEFT_MOUSE to move window action,
# This is the orbit action in Maya interaction mode.
xfconf-query -c xfwm4 -p /general/easy_click -s none

# Start Blender in fullscreen mode
exec /usr/bin/blender -W