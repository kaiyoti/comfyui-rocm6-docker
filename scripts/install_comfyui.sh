#!/bin/bash
set -e

# ===============================================================================================
# COMFYUI INSTALLATION & UPDATE SCRIPT
# ===============================================================================================

APP_DIR="${APP_DIR:-/app}"
COMFYUI_VERSION="${COMFYUI_VERSION:-master}"

# Torch versions for the ROCm fix
TORCH_VERSION="2.9.1"
TORCH_VISION_VERSION="0.24.1"
TORCH_AUDIO_VERSION="2.9.1"

echo "----------------------------------------------------------------"
echo "Checking Core ComfyUI..."

if [ ! -f "${APP_DIR}/main.py" ]; then
    echo "Container: ComfyUI not found in ${APP_DIR}."
    
    # Check if directory is empty or just has garbage
    if [ -d "${APP_DIR}" ]; then
        echo "Container: Destination ${APP_DIR} exists but is missing main.py."
        echo "Container: Performing safe init..."
        
        # Clone to temp directory
        TEMP_CLONE_DIR=$(mktemp -d)
        git clone --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git "$TEMP_CLONE_DIR"
        
        # Copy files over
        echo "Container: Moving files to ${APP_DIR}..."
        cp -rn "$TEMP_CLONE_DIR"/. "${APP_DIR}/" || true
        
        # Clean up
        rm -rf "$TEMP_CLONE_DIR"
    else
        # Standard clone if directory doesn't exist at all
        git clone --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git ${APP_DIR}
    fi
else
    echo "Container: ComfyUI found."
    
    # Update Logic
    if [ -d "${APP_DIR}/.git" ]; then
        echo "Container: Updating ComfyUI (Branch: ${COMFYUI_VERSION})..."
        cd "${APP_DIR}"
        
        # Mark directory safe for git
        git config --global --add safe.directory "${APP_DIR}"
        
        # Fetch, Checkout Master, Pull
        git fetch origin
        git checkout ${COMFYUI_VERSION}
        git pull origin ${COMFYUI_VERSION}
    else
        echo "Container: WARNING - ${APP_DIR} is not a git repository. Cannot auto-update."
    fi
fi

# Ensure requirements are up to date
echo "Container: Verifying core requirements..."
cd ${APP_DIR}
pip install --no-cache-dir -r requirements.txt

# Re-verify Torch versions in case requirements.txt overwrote them
echo "Container: Verifying Torch for ROCm..."
pip uninstall -y torch torchaudio torchvision
pip install --no-cache-dir torch==${TORCH_VERSION} torchvision==${TORCH_VISION_VERSION} torchaudio==${TORCH_AUDIO_VERSION} --index-url https://download.pytorch.org/whl/rocm6.4
