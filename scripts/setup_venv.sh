#!/bin/bash
set -e

# ===============================================================================================
# VIRTUAL ENVIRONMENT SETUP SCRIPT
# ===============================================================================================

# Inherit VENV_DIR from parent or default to /venv
VENV_DIR="${VENV_DIR:-/venv}"

echo "----------------------------------------------------------------"
echo "Initializing Virtual Environment..."

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "   - Venv not found at $VENV_DIR. Creating..."
    python3 -m venv --system-site-packages "$VENV_DIR"
    
    # We use the full path to the venv's python/pip to perform the upgrade
    # This avoids needing to 'source' the venv inside this child script
    echo "   - Upgrading internal pip..."
    "$VENV_DIR/bin/python3" -m pip install --upgrade pip
else
    echo "   - Found existing venv at $VENV_DIR"
fi
