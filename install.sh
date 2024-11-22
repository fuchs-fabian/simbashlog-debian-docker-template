#!/usr/bin/env sh

REPO_URL="https://github.com/fuchs-fabian/simbashlog-debian-docker-template.git" # TODO: Set the git repo url for the project
BRANCH_NAME="main"                                                               # TODO: Set the branch name for the project

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░              GENERAL UTILS               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

abort() {
    echo "ERROR: $1"
    echo "Aborting..."
    exit 1
}

check_command() {
    cmd="$1"

    echo "Checking if the '$cmd' command is available..."
    command -v "$cmd" >/dev/null 2>&1 ||
        abort "The '$cmd' command is not available. Please install it and try again."
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░               PREPARATIONS               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

PROJECT_NAME=$(basename $REPO_URL .git)

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CHECK COMMANDS               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# TODO: Add more commands if needed
check_command "git"
check_command "docker"

echo "Checking if 'docker compose' is available..."
docker compose version >/dev/null 2>&1 ||
    abort "The 'docker compose' command is not available"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║         CHECK FOR PROJECT ARTIFACTS        ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# TODO: Remove this section if not needed

if [ -d "$PROJECT_NAME" ]; then
    echo
    echo "The directory '$PROJECT_NAME' already exists. Remove it? (y/n)"
    read -r REMOVE_DIR
    if [ "$REMOVE_DIR" = "y" ]; then
        rm -rf "$PROJECT_NAME" ||
            abort "Failed to remove the directory '$PROJECT_NAME'"
    else
        abort "The install script cannot continue. You have to set up manually!"
    fi
    echo
fi

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░               INSTALLATION               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

echo
echo "Installing '$PROJECT_NAME'..."

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             CLONE REPOSITORY               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

if [ -z "$BRANCH_NAME" ]; then BRANCH_NAME="main"; fi

echo "Cloning '$REPO_URL' from branch '$BRANCH_NAME'..."

git clone --branch "$BRANCH_NAME" "$REPO_URL" ||
    abort "Failed to clone '$REPO_URL' from branch '$BRANCH_NAME'"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             MOVE TO PROJECT DIR            ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

cd "$PROJECT_NAME" ||
    abort "The directory '$PROJECT_NAME' does not exist. Something went wrong."

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║          CREATE THE '.env' FILE            ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

echo "Setting up the '.env' file..."

LOG_LEVEL=6
CRON_JOB_MINUTES=10
CRON_SCHEDULE="*/$CRON_JOB_MINUTES * * * *"

echo
echo "Enter the git repo url for the 'simbashlog' notifier (press enter if not needed):"
read -r GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER ||
    abort "Failed to read the git repo url for the 'simbashlog' notifier"
echo

# TODO: Add more variables for the '.env' file if needed. Do not forget to add them to the '.env' file creation below.

echo "Creating the '.env' file..."
cat <<EOF >.env
LOG_LEVEL=$LOG_LEVEL
CRON_SCHEDULE=$CRON_SCHEDULE
GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER='$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER'
EOF

cat .env ||
    abort "Failed to create the '.env' file"

echo
echo "The log level is set to '$LOG_LEVEL'"
echo "  (0 = emergency, 1 = alert, 2 = critical, 3 = error, 4 = warning, 5 = notice, 6 = info, 7 = debug)"

echo "The cron job will run every $CRON_JOB_MINUTES minutes."

if [ -n "$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER" ]; then
    echo "The git repo url for the 'simbashlog' notifier is set to '$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER'"
else
    echo "The git repo url for the 'simbashlog' notifier is not set"
fi
echo

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                  CLEANUP                   ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# ┌─────────────────────┬──────────────────────┐
# │               GIT ARTIFACTS                │
# └─────────────────────┴──────────────────────┘

echo "Removing unnecessary git artifacts..."

rm -rf .git ||
    abort "Failed to remove the '.git' directory from the project directory"

rm install.sh ||
    abort "Failed to remove the install script from the project directory"

# TODO: Add more cleanup for git artifacts if needed

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             FINAL EXECUTIONS               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

echo
echo "Do you want to run the Docker container for '$PROJECT_NAME' now? (y/n)"
read -r RUN_CONTAINER
if [ "$RUN_CONTAINER" = "y" ]; then
    echo "Running the Docker container for '$PROJECT_NAME'..."
    docker compose up -d ||
        abort "Failed to run the Docker container"
fi

echo "The installation for '$PROJECT_NAME' is complete"
echo
echo "INFO: If a 'simbashlog' notifier is set and you have to configure it, you have to shut down the container, adjust the configuration and restart the container"
