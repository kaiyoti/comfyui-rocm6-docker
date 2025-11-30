#!/bin/bash
set -e

# ===============================================================================================
# CONFIGURATION
# ===============================================================================================
APP_DIR="${APP_DIR:-/app}"
VENV_DIR="${VENV_DIR:-/venv}"
COMFYUI_VERSION="${COMFYUI_VERSION:-v0.3.75}"
MANAGER_VERSION="${COMFYUI_MANAGER_VERSION:-3.37.1}"

FORCE_NODE_CHECK="${FORCE_NODE_CHECK:-false}"

# ===============================================================================================
# 1. VIRTUAL ENVIRONMENT SETUP
# ===============================================================================================
echo "----------------------------------------------------------------"
echo "Initializing Virtual Environment..."

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "   - Venv not found at $VENV_DIR. Creating..."
    python3 -m venv --system-site-packages "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    echo "   - Upgrading internal pip..."
    pip install --upgrade pip
else
    echo "   - Found existing venv at $VENV_DIR"
    source "$VENV_DIR/bin/activate"
fi

# ===============================================================================================
# Helper Function: install_custom_node
# ===============================================================================================
function install_custom_node() {
    local repo_url=$1
    local dir_name=$2
    local branch=$3
    local target_path="${APP_DIR}/custom_nodes/${dir_name}"
    local install_needed=false

    echo "Checking Node: ${dir_name}..."

    if [ ! -d "$target_path" ]; then
        echo "   - Not found. Cloning..."
        if [ -n "$branch" ]; then
            git clone --branch "$branch" "$repo_url" "$target_path"
        else
            git clone "$repo_url" "$target_path"
        fi
        install_needed=true
    elif [ "$FORCE_NODE_CHECK" = "true" ]; then
        echo "   - Found (FORCE CHECK). Verifying git config..."
        git config --global --add safe.directory "$target_path"
        install_needed=true
    else
        echo "   - Found. Skipping checks."
    fi

    if [ "$install_needed" = "true" ] && [ -f "${target_path}/requirements.txt" ]; then
        echo "   - Installing requirements..."
        cd "$target_path"
        pip install --no-cache-dir -r requirements.txt || echo "   ! WARNING: Requirements failed for ${dir_name}"
    fi
}

# ===============================================================================================
# 2. Core ComfyUI Installation (Robust Method)
# ===============================================================================================
if [ ! -f "${APP_DIR}/main.py" ]; then
    echo "Container: ComfyUI not found in ${APP_DIR}."
    
    # Check if directory is empty or just has garbage
    if [ -d "${APP_DIR}" ]; then
        echo "Container: Destination ${APP_DIR} exists but is missing main.py."
        echo "Container: Performing safe init..."
        
        # Clone to temp directory
        TEMP_CLONE_DIR=$(mktemp -d)
        git clone --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git "$TEMP_CLONE_DIR"
        
        # Copy files over, preserving existing files if any (no-clobber is safer, but we usually want the repo files)
        # using cp -a to preserve permissions and hidden files (.git)
        echo "Container: Moving files to ${APP_DIR}..."
        cp -rn "$TEMP_CLONE_DIR"/. "${APP_DIR}/" || true
        
        # Clean up
        rm -rf "$TEMP_CLONE_DIR"
    else
        # Standard clone if directory doesn't exist at all
        git clone --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git ${APP_DIR}
    fi
    
    cd ${APP_DIR}
    pip install --no-cache-dir -r requirements.txt
else
    echo "Container: ComfyUI found."
fi

# ===============================================================================================
# 3. Custom Nodes Installation
# ===============================================================================================

# Manager
install_custom_node "https://github.com/Comfy-Org/ComfyUI-Manager.git" "comfyui-manager" "${MANAGER_VERSION}"

# Hardware Info (AMD Branch)
install_custom_node "https://github.com/crystian/comfyui-crystools.git" "comfyui-crystools" "AMD"

# GGUF Support
install_custom_node "https://github.com/city96/ComfyUI-GGUF.git" "ComfyUI-GGUF" ""

# Optimization
install_custom_node "https://github.com/welltop-cn/ComfyUI-TeaCache.git" "ComfyUI-TeaCache" ""

# Utilities
install_custom_node "https://github.com/kijai/ComfyUI-KJNodes.git" "ComfyUI-KJNodes" ""

# Video Tools
install_custom_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "ComfyUI-VideoHelperSuite" ""
install_custom_node "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git" "ComfyUI-Frame-Interpolation" ""


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
