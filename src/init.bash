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

declare -r CONST_ORIGINAL_PATH_ENV="$PATH"

declare -r CONST_MAIN_SCRIPT_PATH="/usr/bin/main.bash"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                  LOGGING                   ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

declare -r CONST_LOG_LEVEL_FOR_CURRENT_SCRIPT=6 # Set to '7' for debugging the current script
declare -r CONST_LOG_DIR="/var/log/"
declare -r CONST_CRON_JOB_LOG_FILE="${CONST_LOG_DIR}cron/cron.log"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                  PYTHON                    ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

declare -r CONST_IS_PYTHON_PREINSTALLED=false # If Python is preinstalled, set to 'true', but be careful that Python is correctly installed
declare -r CONST_SYSTEM_PYTHON_PACKAGES=(
    "python3"
    "python3-venv"
    "python3-pip"
)
declare -r CONST_VENV_DIR="/opt/venv/"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                SIMBASHLOG                  ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

declare -r CONST_SIMBASHLOG_NOTIFIER_CONFIG_DIR="/root/.config/simbashlog-notifier"

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

function print_env_var_or_abort {
    local var_name="$1"
    local abort_on_empty="${2:-false}"

    local prefix="[ENV]"

    if [[ "$abort_on_empty" == "true" && -z "${!var_name}" ]]; then
        abort "$prefix '$var_name' not set"
    fi

    echo "$prefix '${var_name}': '${!var_name}'"
}

# TODO: Add all variables that are defined in the 'docker-compose.yml' file under 'environment' here
print_env_var_or_abort "LOG_LEVEL" true
print_env_var_or_abort "CRON_SCHEDULE" true
print_env_var_or_abort "GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER"

# shellcheck disable=SC2153
declare -r CONST_CRON_JOB_LOG_LEVEL="$LOG_LEVEL"
# shellcheck disable=SC2153
declare -r CONST_CRON_JOB_SCHEDULE="$CRON_SCHEDULE"
# shellcheck disable=SC2153
declare -r CONST_GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER="$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER"

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
LOG_LEVEL="$CONST_LOG_LEVEL_FOR_CURRENT_SCRIPT"
# shellcheck disable=SC2034
LOG_LEVEL_FOR_SYSTEM_LOGGING=4
# shellcheck disable=SC2034
FACILITY_NAME_FOR_SYSTEM_LOGGING="user"
# shellcheck disable=SC2034
ENABLE_EXITING_SCRIPT_IF_AT_LEAST_ERROR_IS_LOGGED=false # This must not be 'true' in this script, otherwise the container will not stop if an error occurs
# shellcheck disable=SC2034
ENABLE_DATE_IN_CONSOLE_OUTPUTS_FOR_LOGGING=true
# shellcheck disable=SC2034
SHOW_CURRENT_SCRIPT_NAME_IN_CONSOLE_OUTPUTS_FOR_LOGGING="simple_without_file_extension"

function log_and_abort {
    log_alert "$1"
    log_notice "Container will stop now!"
    exit 1
}

function log_and_fail {
    log_warn "$1"
    return 1
}

function log_debug_var {
    local scope="$1"
    log_debug "$scope -> $(print_var_with_current_value "$2")"
}

function log_debug_delimiter {
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

    log_debug "$separator ${text} $separator"
}

function log_debug_delimiter_start {
    log_debug_delimiter "$1" "$2" ">" false
}

function log_debug_delimiter_end {
    log_debug_delimiter "$1" "$2" "<" false
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
            log_and_fail "Failed to create directory '$dir'"
    else
        log_debug "Directory '$dir' already exists"
    fi
    return 0
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                  PYTHON                    ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function install_python {
    log_info "Installing Python..."

    apt-get update ||
        log_and_abort "Failed to update package lists"

    for package in "${CONST_SYSTEM_PYTHON_PACKAGES[@]}"; do
        log_debug_var "install_python" "package"

        apt-get install -y "$package" ||
            log_and_abort "Failed to install Python! The following package could not be installed: '$package'"
    done

    local venv_dir="$CONST_VENV_DIR"

    log_debug_var "install_python" "venv_dir"

    python3 -m venv $venv_dir ||
        log_and_fail "Failed to create Python virtual environment in '$venv_dir'"

    export PATH="${venv_dir}bin:$PATH" ||
        log_and_fail "Failed to set 'PATH' to include the Python virtual environment in '$venv_dir'"

    log_info "Python installed successfully"

    return 0
}

function uninstall_python {
    log_info "Uninstalling Python..."

    for package in "${CONST_SYSTEM_PYTHON_PACKAGES[@]}"; do
        log_debug_var "install_python" "package"

        apt-get remove --purge -y "$package" ||
            log_and_abort "Failed to uninstall Python! The following package could not be uninstalled: '$package'"
    done

    apt-get autoremove -y ||
        log_and_abort "Failed to autoremove"

    apt-get clean -y ||
        log_and_abort "Failed to clean"

    log_info "Python uninstalled successfully"

    return 0
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

function install_python_simbashlog_notifier {
    local repo_url="$1"

    log_debug_var "install_python_simbashlog_notifier" "repo_url"

    log_info "Installing Python '$CONST_SIMBASHLOG_NAME' notifier from '$repo_url' with pip..."

    local python_packages_before_install
    python_packages_before_install=$(pip freeze)

    pip install --no-cache-dir "git+$repo_url" ||
        log_and_fail "Failed to install Python '$CONST_SIMBASHLOG_NAME' notifier from '$repo_url' with pip"

    local python_packages_after_install
    python_packages_after_install=$(pip freeze)

    local installed_python_packages
    installed_python_packages=$(diff <(echo "$python_packages_before_install") <(echo "$python_packages_after_install") | grep '>' | cut -d' ' -f2)

    echo "$installed_python_packages" | while read -r package; do
        log_debug "Installed Python package: '$package'"
    done

    local notifier
    notifier=$(echo "$installed_python_packages" | grep -E '^simbashlog-.*-notifier(==.*)?$' | cut -d'=' -f1)

    log_debug_var "install_python_simbashlog_notifier" "notifier"

    if is_var_not_empty "$notifier"; then
        log_notice "The following notifier was installed: '$notifier'"
        set_simbashlog_notifier_for_cron_job "$notifier"
    else
        log_warn "No valid Python '$CONST_SIMBASHLOG_NAME' notifier was found. A valid Python '$CONST_SIMBASHLOG_NAME' notifier should start with 'simbashlog-' and end with '-notifier'!"

        log_info "Uninstalling installed Python packages..."
        for package in $installed_python_packages; do
            pip uninstall -y "$package" ||
                log_and_abort "Failed to uninstall Python package '$package'"

            log_debug "Uninstalled Python package: '$package'"
        done

        return 1
    fi

    log_info "Python '$CONST_SIMBASHLOG_NAME' notifier installed successfully"

    return 0
}

function setup_python_simbashlog_notifier {
    local repo_url="$1"

    log_debug_var "setup_python_simbashlog_notifier" "repo_url"

    log_info "Setting up Python '$CONST_SIMBASHLOG_NAME' notifier..."

    local is_python_preinstalled="$CONST_IS_PYTHON_PREINSTALLED"

    log_debug_var "setup_python_simbashlog_notifier" "is_python_preinstalled"

    if is_false "$is_python_preinstalled"; then
        install_python ||
            log_and_fail "Failed to install Python"
    fi

    install_python_simbashlog_notifier "$repo_url" ||
        {
            log_warn "Failed to install Python '$CONST_SIMBASHLOG_NAME' notifier"
            if is_false "$is_python_preinstalled"; then uninstall_python; fi
            return 1
        }

    log_info "Python '$CONST_SIMBASHLOG_NAME' notifier set up successfully"

    return 0
}

function setup_simbashlog_notifier {
    local repo_url="$1"

    log_debug_var "setup_simbashlog_notifier" "repo_url"

    log_info "Setting up '$CONST_SIMBASHLOG_NAME' notifier..."

    local config_dir="$CONST_SIMBASHLOG_NOTIFIER_CONFIG_DIR"

    log_debug_var "setup_simbashlog_notifier" "config_dir"

    create_dir_if_not_exists "$config_dir" ||
        log_and_abort "Failed to create directory '$config_dir'". This is required due to volume mounting!

    if is_var_empty "$repo_url"; then
        log_notice "No notifications will be sent because the repository URL for the '$CONST_SIMBASHLOG_NAME' notifier is not set"
        log_notice "No '$CONST_SIMBASHLOG_NAME' notifier will be installed"
    else
        setup_python_simbashlog_notifier "$repo_url" ||
            log_and_fail "Failed to set up Python '$CONST_SIMBASHLOG_NAME' notifier"
    fi

    log_info "'$CONST_SIMBASHLOG_NAME' notifier set up successfully"

    return 0
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

    log_debug_var "setup_cron_job" "script_name_without_extension"
    log_debug_var "setup_cron_job" "cron_schedule"
    log_debug_var "setup_cron_job" "cron_job_command"

    log_notice "Setting up cron job..."

    local cron_job_log_file="$CONST_CRON_JOB_LOG_FILE"
    local cron_job_file="/etc/cron.d/${script_name_without_extension}_cron_task"
    local cron_job="$cron_schedule SHELL=$SHELL PATH=$PATH /bin/bash $cron_job_command >> $cron_job_log_file 2>&1"

    log_debug_var "setup_cron_job" "cron_job_log_file"
    log_debug_var "setup_cron_job" "cron_job_file"
    log_debug_var "setup_cron_job" "cron_job"
    log_debug_var "setup_cron_job" "SHELL"
    log_debug_var "setup_cron_job" "PATH"

    local cron_job_log_dir
    cron_job_log_dir=$(dirname "$cron_job_log_file")

    log_debug_var "setup_cron_job" "cron_job_log_dir"

    create_dir_if_not_exists "$cron_job_log_dir" ||
        log_and_fail "Failed to create directory '$cron_job_log_dir'"

    log_info "Creating cron job file..."
    echo "$cron_job" >"$cron_job_file" ||
        log_and_fail "Failed to create cron job file '$cron_job_file'"

    log_info "Setting permissions for cron job file..."
    chmod 0644 "$cron_job_file" ||
        log_and_fail "Failed to set permissions for cron job file '$cron_job_file'"

    log_info "Creating cron job log file..."
    touch "$cron_job_log_file" ||
        log_and_fail "Failed to create cron job log file '$cron_job_log_file'"

    log_info "Setting permissions for cron job log file..."
    chmod 0666 "$cron_job_log_file" ||
        log_and_fail "Failed to set permissions for cron job log file '$cron_job_log_file'"

    log_info "Adding cron job..."
    crontab "$cron_job_file" ||
        log_and_fail "Failed to add cron job"

    log_info "Starting cron service..."
    service cron start ||
        log_and_fail "Failed to start cron service"

    log_notice "Cron job set up successfully"

    return 0
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  MAIN                    ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

log_debug "Log level for current script: '$CONST_LOG_LEVEL_FOR_CURRENT_SCRIPT'"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║          SIMBASHLOG NOTIFIER LOGIC         ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

log_debug_delimiter_start 1 "SIMBASHLOG NOTIFIER SETUP"
setup_simbashlog_notifier "$CONST_GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER" ||
    {
        log_warn "No notifications will be sent because the '$CONST_SIMBASHLOG_NAME' notifier setup failed"
        set_simbashlog_notifier_for_cron_job ""
        export PATH="$CONST_ORIGINAL_PATH_ENV"
    }
log_debug_delimiter_end 1 "SIMBASHLOG NOTIFIER SETUP"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║           CRON JOB PREPARATIONS            ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# TODO: Adjust the current section to your needs

function get_cron_job_command {
    local cron_job_command

    cron_job_command="$CONST_MAIN_SCRIPT_PATH \"$CONST_CRON_JOB_LOG_LEVEL\" \"$CONST_LOG_DIR\""

    if is_var_not_empty "$SIMBASHLOG_NOTIFIER_FOR_CRON_JOB"; then
        cron_job_command="$cron_job_command \"$SIMBASHLOG_NOTIFIER_FOR_CRON_JOB\""
    fi

    echo "$cron_job_command"
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CRON JOB LOGIC               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function init_cron_job {
    if file_not_exists "$CONST_MAIN_SCRIPT_PATH"; then
        log_and_fail "Main script '$CONST_MAIN_SCRIPT_PATH' not found"
    fi

    if [[ ! -x "$CONST_MAIN_SCRIPT_PATH" ]]; then
        log_and_fail "Main script '$CONST_MAIN_SCRIPT_PATH' is not executable"
    fi

    local script_name_without_extension
    script_name_without_extension=$(extract_basename_without_file_extensions_from_file "$CONST_MAIN_SCRIPT_PATH")

    if is_var_empty "$script_name_without_extension"; then
        log_and_fail "Could not extract script name without file extension from '$CONST_MAIN_SCRIPT_PATH'"
    fi

    local cron_job_command
    cron_job_command=$(get_cron_job_command)

    if is_var_empty "$cron_job_command"; then
        log_and_fail "Failed to get cron job command"
    fi

    log_debug_delimiter_start 1 "CRON JOB SETUP"
    setup_cron_job "$script_name_without_extension" "$CONST_CRON_JOB_SCHEDULE" "$cron_job_command" ||
        log_and_fail "Failed to set up cron job"
    log_debug_delimiter_end 1 "CRON JOB SETUP"

    return 0
}

init_cron_job ||
    log_and_abort "Failed to initialize cron job"

log_notice "Started successfully"

log_debug "Tail the log file to keep the container running..."
tail -f "$CONST_CRON_JOB_LOG_FILE" ||
    log_and_abort "Failed to tail the log file '$CONST_CRON_JOB_LOG_FILE'"
