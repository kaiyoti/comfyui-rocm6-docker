ARG IMAGE_VERSION="0.0.1"

ARG BASE_IMAGE="docker.io/rocm/pytorch"
ARG BASE_IMAGE_VERSION="rocm6.4.4_ubuntu24.04_py3.12_pytorch_release_2.7.1"

FROM ${BASE_IMAGE}:${BASE_IMAGE_VERSION}

# CHANGED: Set to master to pull the latest bleeding edge version
ARG COMFYUI_VERSION="master" 
ARG COMFYUI_MANAGER_VERSION="3.37.1"
ARG COMFY_CLI_VERSION="1.5.3"
ARG TORCH_VERSION="2.9.1"
ARG TORCH_VISION_VERSION="0.24.1"
ARG TORCH_AUDIO_VERSION="2.9.1"

# Environment variables
ENV APP_DIR="/app"
ENV COMFYUI_VERSION=${COMFYUI_VERSION}
ENV COMFYUI_MANAGER_VERSION=${COMFYUI_MANAGER_VERSION}
ENV TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
ENV CLI_ARGS=""

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies (Added git explicitly)
RUN apt-get update && apt-get install -y curl git python3-venv && \
        rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install --no-cache-dir uv

# --- PRE-CACHING DEPENDENCIES ---
# We clone to a temporary directory to install requirements globally.
RUN mkdir -p /tmp/comfy_install && \
    git clone --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git /tmp/comfy_install && \
    cd /tmp/comfy_install && \
    pip install --no-cache-dir -r requirements.txt && \
    git clone --branch ${COMFYUI_MANAGER_VERSION} https://github.com/Comfy-Org/ComfyUI-Manager.git /tmp/comfy_install/custom_nodes/comfyui-manager && \
    cd /tmp/comfy_install/custom_nodes/comfyui-manager && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /tmp/comfy_install

# Install comfy-cli
RUN pip install --no-cache-dir comfy-cli==${COMFY_CLI_VERSION}

# Fix Torch for ROCm
RUN pip uninstall -y torch torchaudio torchvision && \
    pip install --no-cache-dir torch==${TORCH_VERSION} torchvision==${TORCH_VISION_VERSION} torchaudio==${TORCH_AUDIO_VERSION} --index-url https://download.pytorch.org/whl/rocm6.4


# Set working directory
WORKDIR ${APP_DIR}

# Setup Entrypoint scripts
# We now copy all scripts from the scripts/ folder
COPY scripts/setup_venv.sh /usr/local/bin/setup_venv.sh
COPY scripts/install_comfyui.sh /usr/local/bin/install_comfyui.sh
COPY scripts/install_custom_nodes.sh /usr/local/bin/install_custom_nodes.sh
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    /usr/local/bin/install_custom_nodes.sh \
    /usr/local/bin/install_comfyui.sh \
    /usr/local/bin/setup_venv.sh

EXPOSE 8188

LABEL maintainer="Kaiyoti <kaiyoti.music@gmail.com>" \
    version="${IMAGE_VERSION}" \
    description="ComfyUI with ROCm support (Master Branch)"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# default command
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--use-pytorch-cross-attention", "--disable-xformers"]
