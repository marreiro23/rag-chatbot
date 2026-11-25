#!/usr/bin/env sh
# Base POSIX (sh/bash/zsh): PATH, DMAgentics, .venv, check de .toml e storage remoto

# Descobre a raiz do projeto mesmo se o script for chamado de outra pasta
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# 1. Variáveis e PATH do DMAgentics + ChatBotUI
[ -f "$HOME/.config/dmagentics/path.sh" ] && . "$HOME/.config/dmagentics/path.sh"
export PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"

# 2. Ativa o ambiente virtual Python
VENV_DIR="$PROJECT_ROOT/.venv"
if [ -z "${VIRTUAL_ENV:-}" ] && [ -f "$VENV_DIR/bin/activate" ]; then
  . "$VENV_DIR/bin/activate"
fi

# 3. Configuração de armazenamento remoto
export REMOTE_STORAGE_BACKEND="${REMOTE_STORAGE_BACKEND:-none}"
export REMOTE_STORAGE_NAME="${REMOTE_STORAGE_NAME:-}"
export REMOTE_STORAGE_PATH="${REMOTE_STORAGE_PATH:-}"
export REMOTE_MOUNT_MODE="${REMOTE_MOUNT_MODE:-host}"
export REMOTE_HOST_MOUNT_DIR="${REMOTE_HOST_MOUNT_DIR:-/mnt/remote-storage}"

# 4. Função: Atualiza dependências apenas se o pyproject.toml mudou
sync_toml_if_changed() {
  TOML_FILE="$PROJECT_ROOT/pyproject.toml"
  HASH_FILE="$VENV_DIR/.toml.sha256"

  [ -f "$TOML_FILE" ] || return 0
  command -v sha256sum >/dev/null 2>&1 || return 0

  mkdir -p "$VENV_DIR"
  CURRENT_HASH="$(sha256sum "$TOML_FILE" | awk '{print $1}')"
  SAVED_HASH=""
  [ -f "$HASH_FILE" ] && SAVED_HASH="$(cat "$HASH_FILE")"

  if [ "$CURRENT_HASH" != "$SAVED_HASH" ]; then
    echo "[env] Alteração detectada em pyproject.toml. Atualizando ambiente..."
    if command -v uv >/dev/null 2>&1; then
      uv sync --locked && printf '%s\n' "$CURRENT_HASH" > "$HASH_FILE"
    elif command -v pip >/dev/null 2>&1; then
      pip install -e "$PROJECT_ROOT" && printf '%s\n' "$CURRENT_HASH" > "$HASH_FILE"
    else
      echo "[erro] uv ou pip não encontrados." >&2
      return 1
    fi
  fi
}

# 5. Função: Monta armazenamento remoto se configurado
mount_remote_if_enabled() {
  [ "$REMOTE_STORAGE_BACKEND" = "none" ] && return 0

  if [ -z "$REMOTE_STORAGE_NAME" ]; then
    echo "[erro] Defina REMOTE_STORAGE_NAME para usar armazenamento remoto ($REMOTE_STORAGE_BACKEND)." >&2
    return 1
  fi

  case "$REMOTE_MOUNT_MODE" in
    host)
      command -v rclone >/dev/null 2>&1 || {
        echo "[erro] rclone não instalado no host. Instale com: curl https://rclone.org/install.sh | sudo bash" >&2
        return 1
      }
      mkdir -p "$REMOTE_HOST_MOUNT_DIR"
      if ! mountpoint -q "$REMOTE_HOST_MOUNT_DIR" 2>/dev/null; then
        echo "[storage] Montando ${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH} em $REMOTE_HOST_MOUNT_DIR..."
        rclone mount "${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH}" "$REMOTE_HOST_MOUNT_DIR" \
          --vfs-cache-mode full \
          --allow-other \
          --daemon
        sleep 2
      fi
      ;;
    volume)
      echo "[storage] Modo volume selecionado: o Docker gerenciará o mount via plugin rclone."
      ;;
    *)
      echo "[erro] REMOTE_MOUNT_MODE inválido: $REMOTE_MOUNT_MODE (use 'host' ou 'volume')." >&2
      return 1
      ;;
  esac
}

# 6. Função: Valida requisitos mínimos do sistema
validate_requirements() {
  if ! command -v python >/dev/null 2>&1; then
    echo "[erro] Python não encontrado no PATH." >&2
    return 1
  fi

  PY_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  MIN_PY_VERSION="3.9"
  
  if ! python -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
    echo "[erro] Python 3.9+ necessário, encontrado $PY_VERSION." >&2
    return 1
  fi

  if [ "$PY_VERSION" != "3.13" ] && [ "$PY_VERSION" != "3.12" ] && [ "$PY_VERSION" != "3.11" ] && [ "$PY_VERSION" != "3.10" ] && [ "$PY_VERSION" != "3.9" ]; then
    echo "[aviso] Python $PY_VERSION pode não ser totalmente compatível (recomendado 3.9+)."
  fi

  return 0
}
