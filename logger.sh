#!/bin/bash

ERROR=1
WARN=2
INFO=3
DEBUG=4

LOG_LEVEL=${LOG_LEVEL:-$INFO}

log() {
    local log_level_int=$1
    local log_level_str=$2
    local message=${@:3}
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_message="[$timestamp] [$log_level_str] - $message"

    if [[ $log_level_int -le $LOG_LEVEL ]]; then
        echo $log_message
    fi
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