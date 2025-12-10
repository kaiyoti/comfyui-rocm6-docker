#!/bin/bash
set -e

# ===============================================================================================
# CONFIGURATION
# ===============================================================================================
APP_DIR="${APP_DIR:-/app}"
VENV_DIR="${VENV_DIR:-/venv}"
COMFYUI_VERSION="${COMFYUI_VERSION:-master}"

# Export variables needed by child scripts
export COMFYUI_MANAGER_VERSION="${COMFYUI_MANAGER_VERSION:-3.37.1}"
export FORCE_NODE_CHECK="${FORCE_NODE_CHECK:-false}"
export APP_DIR
export VENV_DIR
export COMFYUI_VERSION

# ===============================================================================================
# 1. VIRTUAL ENVIRONMENT SETUP
# ===============================================================================================

# Run the setup script to create the venv if needed
if [ -f "/usr/local/bin/setup_venv.sh" ]; then
    bash /usr/local/bin/setup_venv.sh
else
    echo "WARNING: /usr/local/bin/setup_venv.sh not found."
fi

# Activate the environment in THIS shell context
# (Crucial: running the script above only creates it; we must source it here)
source "$VENV_DIR/bin/activate"

# ===============================================================================================
# 2. Core ComfyUI Installation & Update
# ===============================================================================================

if [ -f "/usr/local/bin/install_comfyui.sh" ]; then
    bash /usr/local/bin/install_comfyui.sh
else
    echo "WARNING: /usr/local/bin/install_comfyui.sh not found."
fi

# ===============================================================================================
# 3. Custom Nodes Installation
# ===============================================================================================

# Execute the separate installation script
if [ -f "/usr/local/bin/install_custom_nodes.sh" ]; then
    bash /usr/local/bin/install_custom_nodes.sh
else
    echo "WARNING: /usr/local/bin/install_custom_nodes.sh not found."
fi

# ===============================================================================================
# 4. Start Application
# ===============================================================================================
echo "----------------------------------------------------------------"
echo "Container: Starting ComfyUI..."
cd ${APP_DIR}

# Check if arguments were passed
if [ $# -eq 0 ]; then
    # No arguments: Default launch
    exec python main.py
elif [[ "${1#-}" != "$1" ]]; then
    # First arg starts with '-': Assume these are flags (e.g. --listen) and prepend python main.py
    exec python main.py "$@"
else
    # First arg does NOT start with '-': Assume full command (e.g. python3 main.py ...) was passed
    exec "$@"
fi
