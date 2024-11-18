#!/usr/bin/env bash

# DISCLAIMER:
# Not POSIX conform!
#
#
# DESCRIPTION:
# TODO: Add a description

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                LICENSES                  ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

# simbashlog:
# https://github.com/fuchs-fabian/simbashlog/blob/main/LICENSE
#
#
# simbashlog-debian-docker-template:
# https://github.com/fuchs-fabian/simbashlog-debian-docker-template/blob/main/LICENSE

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░              PREPARATIONS                ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

function abort {
    echo "ERROR: $1"
    echo "Aborting..."
    exit 1
}

# TODO: Add more preparations if needed

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    abort "Invalid number of arguments. Usage: $0 <log_level> <log_dir> [<notifier>]"
fi

# shellcheck disable=SC2034
LOG_LEVEL="$1"
# shellcheck disable=SC2034
LOG_DIR="$2"
# shellcheck disable=SC2034
SIMBASHLOG_NOTIFIER="${3:-}"

if [[ -z "$LOG_LEVEL" ]]; then abort "Log level not set"; fi
if [[ -z "$LOG_DIR" ]]; then abort "Log directory not set"; fi

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░              GENERAL UTILS               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

function find_bin_script {
    local script_name="$1"
    local bin_paths=(
        "/bin"
        "/usr/bin"
        "/usr/local/bin"
        "$HOME/bin"
    )

    for bin_path in "${bin_paths[@]}"; do
        local path="$bin_path/$script_name"

        if [ -L "$path" ]; then
            local original_path
            original_path=$(readlink -f "$path")

            if [ -f "$original_path" ]; then
                echo "$original_path"
                return 0
            fi
        elif [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    echo "Error: '$script_name' not found in the specified bin paths (${bin_paths[*]// /, })." >&2
    return 1
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                  LOGGING                   ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# MORE INFO: https://github.com/fuchs-fabian/simbashlog/wiki#use-simbashlog

declare -rx CONST_LOGGER_NAME="simbashlog"

CONST_ORIGINAL_LOGGER_SCRIPT_PATH=$(find_bin_script "$CONST_LOGGER_NAME") ||
    abort "Unable to resolve logger script '$CONST_LOGGER_NAME'"

declare -rx CONST_ORIGINAL_LOGGER_SCRIPT_PATH

# shellcheck source=/dev/null
source "$CONST_ORIGINAL_LOGGER_SCRIPT_PATH" >/dev/null 2>&1 ||
    abort "Unable to source logger script '$CONST_ORIGINAL_LOGGER_SCRIPT_PATH'"

# TODO: Adjust the following log settings or add more if needed

# MORE INFO: https://github.com/fuchs-fabian/simbashlog?tab=readme-ov-file#-before-and-after-sourcing

# shellcheck disable=SC2034
ENABLE_LOG_FILE=true
# shellcheck disable=SC2034
ENABLE_JSON_LOG_FILE=false
# shellcheck disable=SC2034
ENABLE_LOG_TO_SYSTEM=false
# shellcheck disable=SC2034
ENABLE_SIMPLE_LOG_DIR_STRUCTURE=true
# shellcheck disable=SC2034
ENABLE_COMBINED_LOG_FILES=false
# shellcheck disable=SC2034
LOG_LEVEL_FOR_SYSTEM_LOGGING=4
# shellcheck disable=SC2034
FACILITY_NAME_FOR_SYSTEM_LOGGING="user"
# shellcheck disable=SC2034
ENABLE_EXITING_SCRIPT_IF_AT_LEAST_ERROR_IS_LOGGED=true
# shellcheck disable=SC2034
ENABLE_DATE_IN_CONSOLE_OUTPUTS_FOR_LOGGING=true
# shellcheck disable=SC2034
SHOW_CURRENT_SCRIPT_NAME_IN_CONSOLE_OUTPUTS_FOR_LOGGING="simple_without_file_extension"

function log_debug_var {
    local scope="$1"
    log_debug "$scope -> $(print_var_with_current_value "$2")"
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  MAIN                    ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

log_debug_var "VAR" "LOG_LEVEL"

# TODO: Add your code here and delete the following example code

log_debug "This is a debug message"
log_info "This is an info message"
log_notice "This is a notice message"
log_warn "This is a warning message"
log_error "This is an error message"
log_crit "This is a critical message"
log_alert "This is an alert message"
log_emerg "This is an emergency message"
