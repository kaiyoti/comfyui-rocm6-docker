#!/bin/bash
set -e

# ===============================================================================================
# CUSTOM NODE INSTALLATION SCRIPT
# ===============================================================================================

# Ensure variables are available (inherited from entrypoint or set defaults)
APP_DIR="${APP_DIR:-/app}"
MANAGER_VERSION="${COMFYUI_MANAGER_VERSION:-3.37.1}"
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
# Node List
# ===============================================================================================
echo "----------------------------------------------------------------"
echo "Processing Custom Nodes..."

# 1. ComfyUI Manager
install_custom_node "https://github.com/Comfy-Org/ComfyUI-Manager.git" "comfyui-manager" "${MANAGER_VERSION}"

# 2. Hardware Info (AMD Branch) - Example
# install_custom_node "https://github.com/crystian/comfyui-crystools.git" "comfyui-crystools" "AMD"

# 3. GGUF Support - Example
# install_custom_node "https://github.com/city96/ComfyUI-GGUF.git" "ComfyUI-GGUF" ""

echo "Custom node installation complete."
