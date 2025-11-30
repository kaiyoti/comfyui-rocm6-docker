#!/bin/bash
set -e

APP_DIR="${APP_DIR:-/app}"
COMFYUI_VERSION="${COMFYUI_VERSION:-v0.3.75}"
MANAGER_VERSION="${COMFYUI_MANAGER_VERSION:-3.37.1}"

# Default to false. If set to "true", we re-run git config and pip install even if folders exist.
FORCE_NODE_CHECK="${FORCE_NODE_CHECK:-false}"

# ===============================================================================================
# Helper Function: install_custom_node
# ===============================================================================================
function install_custom_node() {
    local repo_url=$1
    local dir_name=$2
    local branch=$3
    local target_path="${APP_DIR}/custom_nodes/${dir_name}"
    local install_needed=false

    echo "----------------------------------------------------------------"
    echo "Checking Node: ${dir_name}..."

    # 1. Check if folder exists
    if [ ! -d "$target_path" ]; then
        echo "   - Not found. Cloning..."
        if [ -n "$branch" ]; then
            git clone --branch "$branch" "$repo_url" "$target_path"
        else
            git clone "$repo_url" "$target_path"
        fi
        install_needed=true
    
    # 2. Folder exists, check if we need to force update/check
    elif [ "$FORCE_NODE_CHECK" = "true" ]; then
        echo "   - Found (FORCE CHECK). Verifying git config..."
        git config --global --add safe.directory "$target_path"
        install_needed=true
    else
        echo "   - Found. Skipping checks."
    fi

    # 3. Install Requirements if needed
    if [ "$install_needed" = "true" ] && [ -f "${target_path}/requirements.txt" ]; then
        echo "   - Installing requirements..."
        cd "$target_path"
        # We allow failure (|| true) so one bad node doesn't crash the whole container
        pip install --no-cache-dir -r requirements.txt || echo "   ! WARNING: Requirements failed for ${dir_name}"
    fi
}

# ===============================================================================================
# 1. Core ComfyUI Installation
# ===============================================================================================
if [ ! -f "${APP_DIR}/main.py" ]; then
    echo "Container: ComfyUI not found. Cloning..."
    git clone --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git ${APP_DIR}
    cd ${APP_DIR}
    pip install --no-cache-dir -r requirements.txt
elif [ "$FORCE_NODE_CHECK" = "true" ]; then
    echo "Container: ComfyUI found (FORCE CHECK). Checking requirements..."
    git config --global --add safe.directory ${APP_DIR}
    cd ${APP_DIR}
    pip install --no-cache-dir -r requirements.txt
else
    echo "Container: ComfyUI found. Skipping Core checks."
fi

# ===============================================================================================
# 2. Custom Nodes Installation
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
# 3. Start Application
# ===============================================================================================
echo "----------------------------------------------------------------"
echo "Container: Starting ComfyUI..."
cd ${APP_DIR}
exec "$@"
