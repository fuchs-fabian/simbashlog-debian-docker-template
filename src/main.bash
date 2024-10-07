#!/usr/bin/env bash

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Invalid number of arguments. Usage: $0 <log_level> [<notifier>]"
    exit 1
fi

LOG_LEVEL="$1"
NOTIFIER="${2:-}"

if [ -z "$LOG_LEVEL" ]; then
    echo "Log level not set"
    exit 1
fi

LOG_DIR="/var/log/main/"

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░             LOGGING HELPER               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

function log {
    local severity="$1"
    local message="$2"

    local log_level="$LOG_LEVEL"
    local log_dir="$LOG_DIR"
    local notifier="$NOTIFIER"

    local simbashlog_action="log"
    local severity_code

    # Set severity code
    case "$severity" in
    debug | 7)
        severity_code=7
        ;;
    info | 6)
        severity_code=6
        ;;
    notice | 5)
        severity_code=5
        ;;
    warn | 4)
        severity_code=4
        ;;
    error | 3)
        severity_code=3
        ;;
    crit | 2)
        severity_code=2
        ;;
    alert | 1)
        severity_code=1
        ;;
    emerg | 0)
        severity_code=0
        ;;
    *)
        # Default to debug if severity is unknown
        severity_code=7
        echo "Unknown severity: $severity"
        ;;
    esac

    local simbashlog_command=("simbashlog" "--action" "$simbashlog_action" "--severity" "$severity_code" "--message" "$message" "--log-level" "$log_level" "--log-dir" "$log_dir")

    # Add notifier if set
    if [ -n "$notifier" ]; then
        simbashlog_command+=("--notifier" "$notifier")
    fi

    # Execute simbashlog command
    "${simbashlog_command[@]}" ||
        {
            echo "Failed to execute: simbashlog"
            exit 1
        }

    # Exit if severity is error or higher
    if [[ "$severity_code" -lt 3 ]]; then
        exit 1
    fi
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  MAIN                    ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

# TODO: Add your code here and delete the following example code

log debug "This is a debug message"
log 7 "This is also a debug message"

log info "This is an info message"
log 6 "This is also an info message"

log notice "This is a notice message"
log 5 "This is also a notice message"

log warn "This is a warning message"
log 4 "This is also a warning message"

log error "This is an error message"
log 3 "This is also an error message"

log crit "This is a critical message"
log 2 "This is also a critical message"

log alert "This is an alert message"
log 1 "This is also an alert message"

log emerg "This is an emergency message"
log 0 "This is also an emergency message"
