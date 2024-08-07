#!/bin/bash

[ -z "${XDG_RUNTIME_DIR}" ] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"
[ -z "${DBUS_SESSION_BUS_ADDRESS}" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
