#!/usr/bin/env sh

SIMBASHLOG_GIT_REPO_URL="https://github.com/fuchs-fabian/simbashlog.git"
SIMBASHLOG_NAME=$(basename "$SIMBASHLOG_GIT_REPO_URL" .git)
SIMBASHLOG_BIN="/bin/$SIMBASHLOG_NAME"
SIMBASHLOG_TMP="/tmp/$SIMBASHLOG_NAME/src/simbashlog.bash"

echo "Cloning repository '$SIMBASHLOG_GIT_REPO_URL'..."
git clone "$SIMBASHLOG_GIT_REPO_URL" "/tmp/$SIMBASHLOG_NAME" ||
    {
        echo "Failed to clone repository"
        exit 1
    }
echo "Cloned repository '$SIMBASHLOG_GIT_REPO_URL' to '/tmp/$SIMBASHLOG_NAME'"

echo "Move '$SIMBASHLOG_TMP' to '$SIMBASHLOG_BIN'..."
mv "$SIMBASHLOG_TMP" "$SIMBASHLOG_BIN" ||
    {
        echo "Failed to move '$SIMBASHLOG_TMP' to '$SIMBASHLOG_BIN'"
        exit 1
    }
echo "Moved '$SIMBASHLOG_TMP' to '$SIMBASHLOG_BIN'"

echo "Remove '/tmp/$SIMBASHLOG_NAME'..."
rm -rf "/tmp/$SIMBASHLOG_NAME" ||
    {
        echo "Failed to remove '/tmp/$SIMBASHLOG_NAME'"
        exit 1
    }
echo "Removed '/tmp/$SIMBASHLOG_NAME'"

echo "Make '$SIMBASHLOG_NAME' executable..."
chmod +x "$SIMBASHLOG_BIN" ||
    {
        echo "Failed to make '$SIMBASHLOG_NAME' executable"
        exit 1
    }
echo "Made '$SIMBASHLOG_NAME' executable"

echo "Checking if '$SIMBASHLOG_NAME' is executable..."
if [ ! -x "$SIMBASHLOG_BIN" ]; then
    echo "$SIMBASHLOG_BIN is not executable"
    exit 1
fi
echo "'$SIMBASHLOG_NAME' is executable"

echo "Checking if '$SIMBASHLOG_NAME' is working..."
if ! simbashlog --version >/dev/null; then
    echo "'$SIMBASHLOG_NAME' is not working"
    exit 1
fi
echo "'$SIMBASHLOG_NAME is working"

echo "'$SIMBASHLOG_NAME $(simbashlog --version) installed successfully."

# Uncomment the following line if you want to debug the script. This will pause the script execution and allow you to see what happened.
#sleep 15
