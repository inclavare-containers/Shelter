#!/bin/bash

ERROR=1
WARN=2
INFO=3
DEBUG=4

LOG_LEVEL=${LOG_LEVEL:-$INFO}

log() {
    local log_level_int=$1

    if [[ $log_level_int -gt $LOG_LEVEL ]]; then
        return
    fi

    case $log_level_int in
        $ERROR)
            # Red
            color="31"
            ;;
        $WARN)
            # Yellow
            color="33"
            ;;
        $DEBUG)
            # Cyan
            color="36"
            ;;
        $INFO)
            # Green
            color="32"
            ;;
        *)
            # Use default color for unrecognized log level
            color="38"
            ;;
    esac

    local log_level_str=$2
    local message=${@:3}
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_message="[$timestamp] [$log_level_str] - $message"
    echo -e "\033[1;${color}m${log_message}\033[0m"
}

error() {
    log $ERROR "ERROR" $@
}

warn() {
    log $WARN "WARN" $@
}

info() {
    log $INFO "INFO" $@
}

debug() {
    log $DEBUG "DEBUG" $@
}

if [[ $LOG_LEVEL -lt $ERROR ]]; then
    LOG_LEVEL=$INFO
fi