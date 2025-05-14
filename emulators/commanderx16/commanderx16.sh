#!/bin/bash

# ------------------------------------------------------------------------------
# Comander X16 install script
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1 - Configuration
# ------------------------------------------------------------------------------

APP_NAME="commanderx16"
ICON_URL="https://github.com/electricwildflower/lgc-scripts/blob/main/emulators/commanderx16/commanderx16.png"
GITHUB_REPO_PRIMARY="https://github.com/X16Community/x16-emulator" # Set to IGNORE to skip GitHub cloning
GITHUB_REPO_SECONDARY="IGNORE" # Set to IGNORE to skip GitHub cloning
IMAGE_STORE_LOCATION="assets/emulator_images/"
RUN_SCRIPT_SUBDIR="run/emulators/" # Subdirectory relative to the project root
JSON_FILE="data/libraries/emulators.json"
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
sudo apt install build-essential libsdl2-dev libreadline-dev libpng-dev zlib1g-dev -y

if $DEPENDENCIES_INSTALLED; then
  echo "Dependencies installed."
else
  echo "Dependencies already satisfied."
fi

# ------------------------------------------------------------------------------
# 4 - Compilation, Making, Installation (if applicable) (with check)
# ------------------------------------------------------------------------------

echo "Checking installation from source (if applicable)..."
SOURCE_INSTALLED=false
EXECUTABLE_PATH="$PROJECT_ROOT/$APP_NAME-src/x16emu" # Adjust if the executable path is different

if [ "$GITHUB_REPO_PRIMARY" != "IGNORE" ] && [ -n "$GITHUB_REPO_PRIMARY" ]; then
    if [ ! -d "$PROJECT_ROOT/$APP_NAME-src" ]; then
        echo "Cloning primary repository: $GITHUB_REPO_PRIMARY"
        git clone "$GITHUB_REPO_PRIMARY" "$PROJECT_ROOT/$APP_NAME-src" || { echo "Error cloning primary repository."; exit 1; }
    fi

    if [ ! -f "$EXECUTABLE_PATH" ]; then
        echo "Building $APP_NAME from source using Make..."
        cd "$PROJECT_ROOT/$APP_NAME-src" || exit 1

        echo "Running make..."
        make -j$(nproc) # Use all available processors for faster build

        if [ $? -eq 0 ]; then
            echo "$APP_NAME built successfully."
            SOURCE_INSTALLED=true
        else
            echo "Error during make."
            exit 1
        fi
        cd .. # Go back to the script's original directory
    else
        echo "$APP_NAME executable already exists at $EXECUTABLE_PATH. Skipping build."
        SOURCE_INSTALLED=true
    fi
fi

if [ "$GITHUB_REPO_SECONDARY" != "IGNORE" ] && [ -n "$GITHUB_REPO_SECONDARY" ]; then
    if [ ! -d "$PROJECT_ROOT/$APP_NAME-secondary-src" ]; then
        echo "Cloning secondary repository: $GITHUB_REPO_SECONDARY"
        git clone "$GITHUB_REPO_SECONDARY" "$PROJECT_ROOT/$APP_NAME-secondary-src" || { echo "Error cloning secondary repository."; exit 1; }
        # Add any necessary build commands for the secondary repository here
    else
        echo "Secondary source directory for $APP_NAME already exists. Skipping cloning."
    fi
fi

# Check for other installation methods (apt, wget appimage, etc.)
APT_INSTALLED=false
# Example for apt:
# if ! dpkg -s <package_name_for_apt> >/dev/null 2>&1; then
#   echo "$APP_NAME is not installed via apt. Installing..."
#   sudo apt install <package_name_for_apt> -y
#   APT_INSTALLED=true
# else
#   echo "$APP_NAME is already installed via apt."
# fi

if $SOURCE_INSTALLED || $APT_INSTALLED; then
    echo "$APP_NAME installation process completed."
else
    echo "$APP_NAME appears to be already installed or installation skipped."
fi

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
  # --- Add your specific run commands and arguments below this line ---
  echo "$APP_NAME" >> "$RUN_SCRIPT_FILE_PATH" # Example command
  # --- Add your specific run commands and arguments above this line ---
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
