#!/usr/bin/env bash
set -euo pipefail

# Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Cloudflare Tunnel
if ! command -v cloudflared >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        mkdir -p /usr/share/keyrings
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
            | tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
        apt-get update
        apt-get install -y cloudflared
    elif [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
        brew install cloudflared
    else
        echo "Unsupported system or package manager. Install cloudflared manually: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
        exit 1
    fi
fi

# Python (uv)
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "uv installation failed or is not on PATH. Install manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

uv sync --locked
