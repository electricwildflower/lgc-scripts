#!/bin/bash

# ------------------------------------------------------------------------------
# Installation Script Template for Linux Game Center
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1 - Configuration (Modify these variables for each application)
# ------------------------------------------------------------------------------

APP_NAME="hedgewars"
ICON_URL="https://github.com/electricwildflower/lgc-scripts/blob/main/opensourcegames/hedgewars/hedgewars.png?raw=true"
GITHUB_REPO_PRIMARY="IGNORE"
GITHUB_REPO_SECONDARY="IGNORE" # Optional
IMAGE_STORE_LOCATION="assets/games_images"
RUN_SCRIPT_SUBDIR="run/games/opensourcegames"
JSON_FILE="data/opensourcegames.json"
PROJECT_ROOT="$HOME/Desktop/linux-gaming-center" # ADJUST THIS TO YOUR ACTUAL DESKTOP PATH

# Construct the full RUN_SCRIPT_LOCATION (for JSON)
RUN_SCRIPT_LOCATION="$RUN_SCRIPT_SUBDIR/$APP_NAME.sh"

# Construct the full IMAGE_STORE_PATH
IMAGE_STORE_PATH="$PROJECT_ROOT/$IMAGE_STORE_LOCATION"

# Construct the full JSON_FILE path
JSON_FILE_PATH="$PROJECT_ROOT/$JSON_FILE"

# Construct the full ICON_PATH
ICON_PATH="$IMAGE_STORE_PATH/$APP_NAME.png"

# Construct the full RUN_SCRIPT_FILE path for creation
RUN_SCRIPT_FILE_PATH="$PROJECT_ROOT/$RUN_SCRIPT_SUBDIR/$APP_NAME.sh"

# ------------------------------------------------------------------------------
# 2 - Check and Install jq if missing
# ------------------------------------------------------------------------------

echo "Checking for jq..."
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed. Attempting to install..."
  sudo apt update
  sudo apt install jq -y
  if command -v jq >/dev/null 2>&1; then
    echo "jq installed successfully."
  else
    echo "Error installing jq. Please install it manually to enable automatic JSON updates."
  fi
fi

# ------------------------------------------------------------------------------
# 3 - Dependencies Installation (with check)
# ------------------------------------------------------------------------------

echo "Checking dependencies (if any)..."
DEPENDENCIES_INSTALLED=false
if ! dpkg -s hedgewars >/dev/null 2>&1; then
  echo "hedgewars is not installed via apt. Installing..."
  sudo apt install hedgewars -y
  DEPENDENCIES_INSTALLED=true
else
  echo "hedgewars is already installed via apt."
fi

if $DEPENDENCIES_INSTALLED; then
  echo "Dependencies installed."
else
  echo "Dependencies already satisfied."
fi

# ------------------------------------------------------------------------------
# 4 - Compilation, Making, Installation (if applicable) (with check)
# ------------------------------------------------------------------------------

echo "Checking installation from source (if applicable)..."
# Skipped due to IGNORE

# Check for apt installation (already done in dependencies)

# Add checks for other installation methods if needed

echo "Installation checks completed."

rm -rf "$PROJECT_ROOT/$APP_NAME-src" "$PROJECT_ROOT/$APP_NAME-secondary-src" 2>/dev/null

# ------------------------------------------------------------------------------
# 5 - Download and Store Icon (with check)
# ------------------------------------------------------------------------------

echo "Checking for icon..."
if [ ! -f "$ICON_PATH" ]; then
  echo "Downloading icon..."
  mkdir -p "$IMAGE_STORE_PATH"
  wget "$ICON_URL" -O "$ICON_PATH" || echo "Warning: Could not download icon."
else
  echo "Icon already exists at $ICON_PATH. Skipping download."
fi

# ------------------------------------------------------------------------------
# 6 - Add Entry to JSON File (with check)
# ------------------------------------------------------------------------------

echo "Checking for entry in $JSON_FILE_PATH..."
if jq -e --arg name "$APP_NAME" '.[] | select(.name == $name)' "$JSON_FILE_PATH" >/dev/null 2>&1; then
  echo "Entry for $APP_NAME already exists in $JSON_FILE_PATH. Skipping addition."
else
  echo "Adding entry to $JSON_FILE_PATH..."
  if command -v jq >/dev/null 2>&1; then
    NEW_JSON_ENTRY=$(cat <<EOF
{
    "name": "$APP_NAME",
    "image": "$IMAGE_STORE_LOCATION/$APP_NAME.png",
    "exec": "$RUN_SCRIPT_LOCATION"
}
EOF
    )
    jq ". += [${NEW_JSON_ENTRY}]" "$JSON_FILE_PATH" > temp_file && mv temp_file "$JSON_FILE_PATH"
  else
    echo "jq is not installed. Please manually add the following entry to $JSON_FILE_PATH:"
    cat <<EOF
{
    "name": "$APP_NAME",
    "image": "$IMAGE_STORE_LOCATION/$APP_NAME.png",
    "exec": "$RUN_SCRIPT_LOCATION"
}
EOF
  fi
fi

# ------------------------------------------------------------------------------
# 7 - Create and Populate Run Script (with check)
# ------------------------------------------------------------------------------

echo "Checking for run script..."
if [ ! -f "$RUN_SCRIPT_FILE_PATH" ]; then
  echo "Creating run script: $RUN_SCRIPT_FILE_PATH"
  mkdir -p "$PROJECT_ROOT/$RUN_SCRIPT_SUBDIR"
  echo "#!/bin/bash" > "$RUN_SCRIPT_FILE_PATH"
  echo "hedgewars" >> "$RUN_SCRIPT_FILE_PATH"
  chmod +x "$RUN_SCRIPT_FILE_PATH"
else
  echo "Run script already exists at $RUN_SCRIPT_FILE_PATH. Skipping creation."
fi

# ------------------------------------------------------------------------------
# 8 - Success Message
# ------------------------------------------------------------------------------

echo "------------------------------------------------------------------------------"
echo "Setup for $APP_NAME completed!"
echo "It should now be available in the Linux Game Center."
echo "------------------------------------------------------------------------------"

exit 0
