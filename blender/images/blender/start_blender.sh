#!/usr/bin/bash

# Symlink cached blender kernels
if [[ -d /opt/blender/cache/cycles/kernels ]]; then
    echo "INFO: copying cached kernels from /opt/blender/cache/cycles/kernels/"
    mkdir -p ${HOME}/.cache/cycles/kernels/
    ls /opt/blender/cache/cycles/kernels/* | xargs -I {} ln -sf {} ${HOME}/.cache/cycles/kernels/
fi

# Disable window manager ALT+LEFT_MOUSE to move window action,
# This is the orbit action in Maya interaction mode.
xfconf-query -c xfwm4 -p /general/easy_click -s none

# Start Blender in fullscreen mode
exec /usr/bin/blender -W $@