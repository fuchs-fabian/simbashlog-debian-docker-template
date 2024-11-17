#!/usr/bin/env bash

# IMPORTANT: The repo must contain a script file with the same name as the repo name!

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                CONSTANTS                 ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

declare -r CONST_DEFAULT_BRANCH_NAME="main"

declare -r CONST_TMP_PATH="/tmp"
declare -r CONST_BIN_PATH="/usr/bin"

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░              GENERAL UTILS               ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

function abort {
    echo "ERROR: $1"
    echo "Aborting..."
    exit 1
}

function check_command {
    cmd="$1"

    command -v "$cmd" >/dev/null 2>&1 ||
        {
            echo "The '$cmd' command is not available"
            return 1
        }
    return 0
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║    FILE & DIRECTORY HANDLING FUNCTIONS     ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function find_script_file {
    local search_dir="$1"
    local script_name="$2"

    local file_extensions=(
        ".sh"
        ".bash"
        ".zsh"
        ""
    )

    for file_extension in "${file_extensions[@]}"; do
        local script_path
        script_path=$(find "$search_dir" -type f -name "${script_name}${file_extension}" 2>/dev/null | head -n 1)

        if [[ -n "$script_path" ]]; then
            echo "$script_path"
            return 0
        fi
    done

    echo "Script file with name '$script_name' and accepted extensions $(printf "'%s' " "${file_extensions[@]}")not found"
    return 1
}

function make_executable {
    local script_path="$1"

    chmod +x "$script_path" ||
        {
            echo "Failed to make '$script_path' executable"
            return 1
        }
    return 0
}

function remove_dir {
    local dir_path="$1"

    if [[ -d "$dir_path" ]]; then
        rm -rf "$dir_path" ||
            {
                echo "Failed to remove directory '$dir_path'"
                return 1
            }
        return 0
    fi
    echo "Directory '$dir_path' does not exist"
    return 1
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║        SCRIPT FUNCTIONALITY CHECKS         ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function check_if_script_is_working {
    local script_name="$1"

    local options=(
        "-v"
        "--version"
        "-h"
        "--help"
    )

    for option in "${options[@]}"; do
        if "$script_name" "$option" >/dev/null 2>&1; then
            return 0
        fi
    done

    echo "'$script_name' does not respond to options $(printf "'%s' " "${options[@]}")"
    return 1
}

function get_version {
    local script_name="$1"

    local version
    version=$("$script_name" -v 2>/dev/null)

    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi

    version=$("$script_name" --version 2>/dev/null)

    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi

    return 1
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  LOGIC                   ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

function get_script_name_from_repo_url {
    basename "$1" .git
}

function clone_repo {
    local repo_url="$1"
    local branch_name="$2"
    local destination_path="$3"

    check_command "git" || return 1

    if [[ -z "$branch_name" ]]; then branch_name="$CONST_DEFAULT_BRANCH_NAME"; fi

    git clone --branch "$branch_name" "$repo_url" "$destination_path" ||
        {
            echo "Failed to clone '$script_name' from branch '$branch_name'"
            return 1
        }
    return 0
}

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                INSTALLATION                ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

function install {
    local repo_url="$1"
    local branch_name="$2"

    local script_name
    script_name=$(get_script_name_from_repo_url "$repo_url")

    local repo_path="$CONST_TMP_PATH/$script_name"

    echo "Cloning '$script_name' from branch '$branch_name'..."
    clone_repo "$repo_url" "$branch_name" "$repo_path" ||
        abort "Cloning failed"

    echo "Finding script file for '$script_name'..."
    local script_path
    script_path=$(find_script_file "$repo_path" "$script_name") ||
        abort "Script file not found"

    echo "Moving '$script_name' to bin path '$CONST_BIN_PATH' without extension..."
    mv "$script_path" "$CONST_BIN_PATH/$script_name" ||
        abort "Failed to move '$script_name' to '$CONST_BIN_PATH'"

    echo "Making '$script_name' executable..."
    make_executable "$CONST_BIN_PATH/$script_name" ||
        abort "Failed to make '$script_name' executable"

    echo "Checking if '$script_name' is working..."
    check_if_script_is_working "$script_name" ||
        abort "'$script_name' is not working"

    echo "Cleaning up temporary files..."
    remove_dir "$repo_path" ||
        abort "Failed to remove temporary files in '$repo_path'"

    local version
    version=$(get_version "$script_name") ||
        echo "No version found for '$script_name'"

    if [[ -n "$version" ]]; then
        echo "Version: $version"
    fi

    echo "Installation of '$script_name' successful"
}

# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░
# ░░                                          ░░
# ░░                                          ░░
# ░░                  MAIN                    ░░
# ░░                                          ░░
# ░░                                          ░░
# ░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    abort "Invalid number of arguments. Usage: $0 <repo_url> [<branch_name>]"
fi

REPO_URL="$1"
BRANCH_NAME="${2:-}"

if [[ -z "$REPO_URL" ]]; then
    abort "Repo URL not set"
fi

install "$REPO_URL" "$BRANCH_NAME"

# Uncomment the following line if you want to debug the script. This will pause the script execution and allow you to see what happened.
#sleep 15
