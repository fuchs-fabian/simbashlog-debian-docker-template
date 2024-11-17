#!/usr/bin/env bash

# DISCLAIMER:
# Not POSIX conform!
#
#
# DESCRIPTION:
# This script sets up a cron job for a main script.

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
# ░░                CONSTANTS                 ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

declare -r CONST_UNINSTALL_PYTHON_IF_SIMBASHLOG_NOTIFIER_NOT_FOUND=true # Set to 'false' if you want to keep Python installed even if the notifier is not found
declare -r CONST_SIMBASHLOG_NOTIFIER_CONFIG_DIR="/root/.config/simbashlog-notifier"
declare -r CONST_LOG_DIR="/var/log/"
declare -r CONST_CRON_JOB_LOG_FILE="/var/log/cron.log"

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

if [[ -z "$LOG_LEVEL" ]]; then abort "'LOG_LEVEL' not set"; fi
if [[ -z "$CRON_SCHEDULE" ]]; then abort "'CRON_SCHEDULE' not set"; fi

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

declare -rx CONST_LOGGER_NAME="simbashlog"

CONST_ORIGINAL_LOGGER_SCRIPT_PATH=$(find_bin_script "$CONST_LOGGER_NAME") ||
    abort "Unable to resolve logger script '$CONST_LOGGER_NAME'"

declare -rx CONST_ORIGINAL_LOGGER_SCRIPT_PATH

# shellcheck source=/dev/null
source "$CONST_ORIGINAL_LOGGER_SCRIPT_PATH" >/dev/null 2>&1 ||
    abort "Unable to source logger script '$CONST_ORIGINAL_LOGGER_SCRIPT_PATH'"

# shellcheck disable=SC2034
ENABLE_LOG_FILE=true
# shellcheck disable=SC2034
ENABLE_JSON_LOG_FILE=false
# shellcheck disable=SC2034
ENABLE_LOG_TO_SYSTEM=false
# shellcheck disable=SC2034
LOG_DIR="$CONST_LOG_DIR"
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

function log_delimiter {
    local level="$1"
    local text="$2"
    local char="$3"
    local use_uppercase="$4"
    local number
    local separator=""

    case $level in
    1) number=15 ;;
    2) number=10 ;;
    3) number=5 ;;
    *) number=3 ;;
    esac

    for ((i = 0; i < number; i++)); do
        separator+="$char"
    done

    if is_true "$use_uppercase"; then
        text=$(to_uppercase "$text")
    fi

    log_info "$separator ${text} $separator"
}

function log_delimiter_start {
    log_delimiter "$1" "$2" ">" false
}

function log_delimiter_end {
    log_delimiter "$1" "$2" "<" false
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  LOGIC                   ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

function create_dir_if_not_exists {
    local dir="$1"

    log_debug_var "create_dir_if_not_exists" "dir"

    if directory_not_exists "$dir"; then
        log_info "Creating directory '$dir'..."

        mkdir -p "$dir" ||
            log_error "Failed to create directory '$dir'"
    fi
}

function uninstall_python {
    log_delimiter_start 2 "UNINSTALL PYTHON"

    apt-get remove --purge -y python3 python3-venv python3-pip
    apt-get autoremove -y
    apt-get clean

    log_delimiter_end 2 "UNINSTALL PYTHON"
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║         SIMBASHLOG NOTIFIER SETUP          ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

SIMBASHLOG_NOTIFIER_FOR_CRON_JOB=""

function set_simbashlog_notifier_for_cron_job {
    local notifier="$1"

    log_debug_var "set_simbashlog_notifier_for_cron_job" "notifier"

    SIMBASHLOG_NOTIFIER_FOR_CRON_JOB="$notifier"
}

function setup_simbashlog_notifier {
    local repo_url="$1"

    log_delimiter_start 1 "SIMBASHLOG NOTIFIER SETUP"

    log_debug_var "setup_simbashlog_notifier" "repo_url"

    local config_dir="$CONST_SIMBASHLOG_NOTIFIER_CONFIG_DIR"

    log_debug_var "setup_simbashlog_notifier" "config_dir"

    if is_var_empty "$repo_url"; then
        log_warn "Git repository URL for '$CONST_SIMBASHLOG_NAME' notifier not set. Therefore, no notifications will be sent."

        if is_true "$CONST_UNINSTALL_PYTHON_IF_SIMBASHLOG_NOTIFIER_NOT_FOUND"; then uninstall_python; fi
    else
        create_dir_if_not_exists "$config_dir"

        local python_packages_before_install
        python_packages_before_install=$(pip freeze)

        pip install --no-cache-dir "git+$repo_url" ||
            log_error "Failed to install '$CONST_SIMBASHLOG_NAME' notifier from '$repo_url'"

        local python_packages_after_install
        python_packages_after_install=$(pip freeze)

        local installed_python_packages
        installed_python_packages=$(diff <(echo "$python_packages_before_install") <(echo "$python_packages_after_install") | grep '>' | cut -d' ' -f2)

        echo "$installed_python_packages" | while read -r package; do
            log_debug "Installed python package: $package"
        done

        local notifier
        notifier=$(echo "$installed_python_packages" | grep -E '^simbashlog-.*-notifier(==.*)?$' | cut -d'=' -f1)

        if is_var_not_empty "$notifier"; then
            log_notice "The following notifier was installed: '$notifier'"
        else
            log_warn "No valid '$CONST_SIMBASHLOG_NAME' notifier was found. A valid '$CONST_SIMBASHLOG_NAME' notifier should start with 'simbashlog-' and end with '-notifier'."

            log_info "Reverting installation, uninstalling installed python packages..."
            for package in $installed_python_packages; do
                pip uninstall -y "$package" ||
                    log_error "Failed to uninstall '$package'"

                log_debug "Uninstalled python package: '$package'"
            done

            if is_true "$CONST_UNINSTALL_PYTHON_IF_SIMBASHLOG_NOTIFIER_NOT_FOUND"; then uninstall_python; fi
        fi

        set_simbashlog_notifier_for_cron_job "$notifier"

        log_delimiter_end 1 "SIMBASHLOG NOTIFIER SETUP"
    fi
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CRON JOB SETUP               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function setup_cron_job {
    local script_name_without_extension="$1"
    local cron_schedule="$2"
    local cron_job_command="$3"

    log_delimiter_start 1 "CRON JOB SETUP"

    log_debug_var "setup_cron_job" "script_name_without_extension"
    log_debug_var "setup_cron_job" "cron_schedule"
    log_debug_var "setup_cron_job" "cron_job_command"

    local cron_job_file="/etc/cron.d/${script_name_without_extension}_cron_task"
    local cron_job_log_file="$CONST_CRON_JOB_LOG_FILE"
    local cron_job="$cron_schedule SHELL=$SHELL PATH=$PATH /bin/bash $cron_job_command >> $cron_job_log_file 2>&1"

    log_debug_var "setup_cron_job" "cron_job_file"
    log_debug_var "setup_cron_job" "cron_job_log_file"
    log_debug_var "setup_cron_job" "cron_job"
    log_debug_var "setup_cron_job" "SHELL"
    log_debug_var "setup_cron_job" "PATH"

    log_info "Creating cron job file..."
    echo "$cron_job" >"$cron_job_file" ||
        log_error "Failed to create cron job file '$cron_job_file'"

    log_info "Setting permissions for cron job file..."
    chmod 0644 "$cron_job_file" ||
        log_error "Failed to set permissions for cron job file '$cron_job_file'"

    log_info "Creating cron job log file..."
    touch "$cron_job_log_file" ||
        log_error "Failed to create cron job log file '$cron_job_log_file'"

    log_info "Setting permissions for cron job log file..."
    chmod 0666 "$cron_job_log_file" ||
        log_error "Failed to set permissions for cron job log file '$cron_job_log_file'"

    log_info "Adding cron job..."
    crontab "$cron_job_file" ||
        log_error "Failed to add cron job"

    log_info "Starting cron service..."
    service cron start ||
        log_error "Failed to start cron service"

    log_notice "Cron job set up successfully"

    log_delimiter_end 1 "CRON JOB SETUP"
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  MAIN                    ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║           ENVIRONMENT VARIABLES            ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

log_debug_var "ENV" "LOG_LEVEL"
log_debug_var "ENV" "CRON_SCHEDULE"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║          SIMBASHLOG NOTIFIER LOGIC         ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

setup_simbashlog_notifier "$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║           CRON JOB PREPARATIONS            ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# TODO: Adjust the current section to your needs, but the following variables are required: 'MAIN_BIN', 'CRON_JOB_COMMAND'

MAIN_BIN="/usr/bin/main.bash"

if is_var_not_empty "$SIMBASHLOG_NOTIFIER_FOR_CRON_JOB"; then
    CRON_JOB_COMMAND="$MAIN_BIN \"$LOG_LEVEL\" \"$SIMBASHLOG_NOTIFIER_FOR_CRON_JOB\""
else
    CRON_JOB_COMMAND="$MAIN_BIN \"$LOG_LEVEL\""
fi

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CRON JOB LOGIC               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

if is_var_empty "$CRON_JOB_COMMAND"; then log_error "'CRON_JOB_COMMAND' not set"; fi

SCRIPT_NAME_WITHOUT_EXTENSION=$(extract_basename_without_file_extensions_from_file "$MAIN_BIN")
if is_var_empty "$SCRIPT_NAME_WITHOUT_EXTENSION"; then log_error "'SCRIPT_NAME_WITHOUT_EXTENSION' not set. Something went wrong."; fi

if file_not_exists "$MAIN_BIN"; then log_error "Main script '$MAIN_BIN' not found"; fi
if [[ ! -x "$MAIN_BIN" ]]; then log_error "Main script '$MAIN_BIN' is not executable"; fi

setup_cron_job "$SCRIPT_NAME_WITHOUT_EXTENSION" "$CRON_SCHEDULE" "$CRON_JOB_COMMAND"

log_notice "Started successfully"

log_debug "Tail the log file to keep the container running..."
tail -f "$CONST_CRON_JOB_LOG_FILE" ||
    log error "Failed to tail the log file '$CONST_CRON_JOB_LOG_FILE'"
