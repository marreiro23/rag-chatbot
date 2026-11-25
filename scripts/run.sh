#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Define the usage function
usage() {
    echo "Usage: $0 [--cloudflare] [--help]"
    echo ""
    echo "Options:"
    echo "  --cloudflare    Start Cloudflare tunnel for external access"
    echo "  --help          Show this help message"
    exit 1
}

# Initialize CLOUDFLARE variable
CLOUDFLARE=""

# Loop through command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cloudflare)
            CLOUDFLARE=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Carrega variáveis de ambiente e .venv
. "$SCRIPT_DIR/env.sh"

# Valida requisitos mínimos do ambiente
echo "[install] Validando requisitos do sistema..."
if ! validate_requirements; then
    echo "[erro] Validação de requisitos falhou." >&2
    exit 1
fi

# Sincroniza dependências se pyproject.toml mudou
echo "[install] Verificando dependências..."
if ! sync_toml_if_changed; then
    echo "[erro] Falha ao sincronizar dependências." >&2
    exit 1
fi

# Monta armazenamento remoto se configurado
if [ "$REMOTE_STORAGE_BACKEND" != "none" ]; then
    echo "[install] Configurando armazenamento remoto..."
    if ! mount_remote_if_enabled; then
        echo "[aviso] Falha ao montar armazenamento remoto, continuando sem ele..."
    fi
fi

# Ensure uv is available
if ! command -v uv >/dev/null 2>&1; then
    echo "uv is required. Install it first with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

cd "$PROJECT_ROOT"

# Run the Python app
uv run python -m rag_chatbot --host localhost &
APP_PID=$!

cleanup() {
    if [[ -n ${TUNNEL_PID:-} ]] && kill -0 "$TUNNEL_PID" 2>/dev/null; then
        kill "$TUNNEL_PID" 2>/dev/null || true
        wait "$TUNNEL_PID" 2>/dev/null || true
    fi
    if kill -0 "$APP_PID" 2>/dev/null; then
        kill "$APP_PID" 2>/dev/null || true
        wait "$APP_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

if [[ -z $CLOUDFLARE ]]; then
    wait "$APP_PID"
    exit $?
fi

if ! command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared is required for --cloudflare."
    echo "Install it with: bash ./scripts/install_extra.sh"
    exit 1
fi

# Give Gradio time to bind before starting the outbound tunnel.
for _ in $(seq 1 60); do
    if curl --fail --silent --output /dev/null http://127.0.0.1:7860/; then
        break
    fi
    if ! kill -0 "$APP_PID" 2>/dev/null; then
        echo "The RAG Chatbot process stopped before the tunnel could start."
        exit 1
    fi
    sleep 1
done

if [[ -n ${CLOUDFLARE_TUNNEL_TOKEN:-} ]]; then
    cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN" &
else
    echo "Starting an ephemeral Cloudflare Quick Tunnel. No account or token is required."
    cloudflared tunnel --no-autoupdate --url http://127.0.0.1:7860 &
fi
TUNNEL_PID=$!

wait "$TUNNEL_PID"
