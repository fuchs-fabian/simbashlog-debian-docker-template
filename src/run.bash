#!/usr/bin/env bash

if [ -z "$LOG_LEVEL" ]; then
    echo "Log level not set"
    exit 1
fi

NOTIFIER=""
LOG_DIR="/var/log/run/"

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

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║            SIMBASHLOG NOTIFIER             ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function uninstall_python {
    log info "Uninstalling python..."
    apt-get remove --purge -y python3 python3-venv python3-pip
    apt-get autoremove -y
    apt-get clean
}

NOTIFIER_CONFIG_DIR="/root/.config/simbashlog-notifier"

log debug "Creating directory '$NOTIFIER_CONFIG_DIR'..."
mkdir -p "$NOTIFIER_CONFIG_DIR" ||
    log error "Failed to create directory '$NOTIFIER_CONFIG_DIR'"

log debug "Checking if 'GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER' is set..."
if [ -z "$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER" ]; then
    log warn "Git repository URL for 'simbashlog' notifier not set. Therefore, no notifications will be sent."

    # TODO: Remove the following line if you still need python
    uninstall_python
else
    PYTHON_PACKAGES_BEFORE_INSTALL=$(pip freeze)

    pip install --no-cache-dir "git+$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER" ||
        log error "Failed to install 'simbashlog' notifier from '$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER'"

    PYTHON_PACKAGES_AFTER_INSTALL=$(pip freeze)

    INSTALLED_PYTHON_PACKAGES=$(diff <(echo "$PYTHON_PACKAGES_BEFORE_INSTALL") <(echo "$PYTHON_PACKAGES_AFTER_INSTALL") | grep '>' | cut -d' ' -f2)

    echo "$INSTALLED_PYTHON_PACKAGES" | while read -r package; do
        log debug "Installed python package: $package"
    done

    NOTIFIER=$(echo "$INSTALLED_PYTHON_PACKAGES" | grep -E '^simbashlog-.*-notifier(==.*)?$' | cut -d'=' -f1)

    if [ -n "$NOTIFIER" ]; then
        log info "The following notifier was installed: $NOTIFIER"
    else
        log warn "No valid 'simbashlog' notifier was found. A valid simbashlog notifier should start with 'simbashlog-' and end with '-notifier'."

        log info "Reverting installation, uninstalling installed python packages..."
        for package in $INSTALLED_PYTHON_PACKAGES; do
            pip uninstall -y "$package" ||
                log error "Failed to uninstall $package"

            log info "Uninstalled python package: $package"
        done

        # TODO: Remove the following line if you still need python
        uninstall_python
    fi
fi

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                   MAIN                     ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# TODO: Adjust the current section to your needs, but the following variables are required: `SCRIPT_NAME_WITHOUT_EXTENSION`, `CRON_JOB_COMMAND`

MAIN_BIN="/bin/main.bash"

SCRIPT_NAME_WITHOUT_EXTENSION="main"

log debug "Checking if '$MAIN_BIN' is executable..."
if [ ! -f "$MAIN_BIN" ]; then
    log error "'$MAIN_BIN' not found"
fi

if [ -n "$NOTIFIER" ]; then
    CRON_JOB_COMMAND="$MAIN_BIN \"$LOG_LEVEL\" \"$NOTIFIER\""
else
    CRON_JOB_COMMAND="$MAIN_BIN \"$LOG_LEVEL\""
fi

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CRON JOB SETUP               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

log info "Setting up cron job..."

log debug "Script name without extension: $SCRIPT_NAME_WITHOUT_EXTENSION"
log debug "Cron job command: $CRON_JOB_COMMAND"

if [ -z "$CRON_SCHEDULE" ]; then
    log error "Cron schedule not set"
fi
log debug "Cron schedule: $CRON_SCHEDULE"

CRON_JOB_FILE="/etc/cron.d/${SCRIPT_NAME_WITHOUT_EXTENSION}_cron_task"
log debug "Cron job file: $CRON_JOB_FILE"

CRON_JOB_LOG_FILE="/var/log/cron.log"
log debug "Cron job log file: $CRON_JOB_LOG_FILE"

log debug "SHELL: $SHELL"
log debug "PATH: $PATH"

CRON_JOB="$CRON_SCHEDULE SHELL=$SHELL PATH=$PATH /bin/bash $CRON_JOB_COMMAND >> $CRON_JOB_LOG_FILE 2>&1"
log debug "Cron job: $CRON_JOB"

log debug "Creating cron job file..."
echo "$CRON_JOB" >"$CRON_JOB_FILE" ||
    log error "Failed to create cron job file '$CRON_JOB_FILE'"

log debug "Setting permissions for cron job file..."
chmod 0644 "$CRON_JOB_FILE" ||
    log error "Failed to set permissions for cron job file '$CRON_JOB_FILE'"

log debug "Creating cron job log file..."
touch "$CRON_JOB_LOG_FILE" ||
    log error "Failed to create cron job log file '$CRON_JOB_LOG_FILE'"

log debug "Setting permissions for cron job log file..."
chmod 0666 "$CRON_JOB_LOG_FILE" ||
    log error "Failed to set permissions for cron job log file '$CRON_JOB_LOG_FILE'"

log debug "Setting up cron job..."
crontab "$CRON_JOB_FILE" ||
    log error "Failed to set up cron job"

log debug "Starting cron service..."
service cron start ||
    log error "Failed to start cron service"

log info "Cron job set up successfully"

log info "Started successfully"

log debug "Tail the log file to keep the container running..."
tail -f "$CRON_JOB_LOG_FILE" ||
    log error "Failed to tail the log file '$CRON_JOB_LOG_FILE'"
