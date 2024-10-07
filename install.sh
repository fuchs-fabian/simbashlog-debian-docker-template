#!/usr/bin/env sh

PROJECT_GIT_REPO_URL="https://github.com/fuchs-fabian/simbashlog-debian-docker-template.git" # TODO: Set the git repo url for the project
PROJECT_NAME=$(basename $PROJECT_GIT_REPO_URL .git)

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░               PREPARATIONS               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CHECK COMMANDS               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

check_command() {
    cmd="$1"

    echo "Checking if the '$cmd' command is available..."
    command -v "$cmd" >/dev/null 2>&1 ||
        {
            echo "The '$cmd' command is not available. Please install it and try again."
            exit 1
        }
    echo "The '$cmd' command is available."
}

# TODO: Add more commands if needed
check_command "git"
check_command "docker"

echo "Checking if 'docker compose' is available..."
docker compose version >/dev/null 2>&1 ||
    {
        echo "The 'docker compose' command is not available."
        exit 1
    }
echo "The 'docker compose' command is available."

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║         CHECK FOR PROJECT ARTIFACTS        ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# TODO: Remove this if not needed

if [ -d "$PROJECT_NAME" ]; then
    echo
    echo "The directory '$PROJECT_NAME' already exists. Remove it? (y/n)"
    read -r REMOVE_DIR
    if [ "$REMOVE_DIR" = "y" ]; then
        rm -rf "$PROJECT_NAME" ||
            {
                echo "Failed to remove the directory '$PROJECT_NAME'."
                exit 1
            }
        echo
    else
        echo "The install script cannot continue. You have to set up manually."
        echo "Aborting..."
        exit 1
    fi
fi

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             CLONE REPOSITORY               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

echo "Cloning the repository '$PROJECT_GIT_REPO_URL'..."
git clone $PROJECT_GIT_REPO_URL ||
    {
        echo "Failed to clone the repository '$PROJECT_GIT_REPO_URL'."
        exit 1
    }
echo "The repository '$PROJECT_GIT_REPO_URL' has been cloned."

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             MOVE TO PROJECT DIR            ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

cd "$PROJECT_NAME" ||
    {
        echo "The directory '$PROJECT_NAME' does not exist. Something went wrong."
        exit 1
    }

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░               INSTALLATION               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

echo "Installing '$PROJECT_NAME'..."

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
echo "Enter the git repo url for the 'simbashlog' notifier (leave empty if not needed):"
read -r GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER ||
    {
        echo "Failed to read the git repo url for the 'simbashlog' notifier."
        exit 1
    }
export GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER
echo

# TODO: Add more variables for the '.env' file if needed. Do not forget to add them to the '.env' file creation below.

echo "Creating the '.env' file..."
cat <<EOF >.env
LOG_LEVEL=$LOG_LEVEL
CRON_SCHEDULE=$CRON_SCHEDULE
GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER='$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER'
EOF

cat .env ||
    {
        echo "Failed to create the '.env' file."
        exit 1
    }
echo "The '.env' file has been created."

echo

echo "The log level is set to '$LOG_LEVEL'."
echo "  (0 = emergency, 1 = alert, 2 = critical, 3 = error, 4 = warning, 5 = notice, 6 = info, 7 = debug)"

echo "The cron job will run every $CRON_JOB_MINUTES minutes."

if [ -n "$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER" ]; then
    echo "The git repo url for the 'simbashlog' notifier is set to '$GIT_REPO_URL_FOR_SIMBASHLOG_NOTIFIER'."
else
    echo "The git repo url for the 'simbashlog' notifier is not set."
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
    {
        echo "Failed to remove the '.git' directory from the project directory."
        exit 1
    }
echo "The '.git' directory has been removed from the project directory."

rm install.sh ||
    {
        echo "Failed to remove the install script from the project directory."
        exit 1
    }
echo "The install script has been removed from the project directory."

# TODO: Add more cleanup for git artifacts if needed

# ┌─────────────────────┬──────────────────────┐
# │               INSTALL SCRIPT               │
# └─────────────────────┴──────────────────────┘

echo "Removing the current install script..."

rm ../install.sh ||
    {
        echo "Failed to remove the current install script."
        exit 1
    }
echo "The current install script has been removed."

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             FINAL EXECUTIONS               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

echo "Running the Docker container for '$PROJECT_NAME'..."
docker compose up -d ||
    {
        echo "Failed to run the Docker container."
        exit 1
    }
echo "The Docker container is running."

echo "The installation for '$PROJECT_NAME' is complete."
echo
echo "INFO: If a 'simbashlog' notifier is set and you have to configure it, you have to shut down the container, adjust the configuration and restart the container."
