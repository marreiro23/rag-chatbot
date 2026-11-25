#!/usr/bin/env sh
# Script de instalação principal
# Suporta múltiplos shells (bash, zsh, fish, sh)
# Integra armazenamento remoto via Rclone
# Sincroniza dependências automaticamente

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Cores para output (opcional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
  printf "${BLUE}[info]${NC} %s\n" "$1"
}

echo_success() {
  printf "${GREEN}[ok]${NC} %s\n" "$1"
}

echo_warn() {
  printf "${YELLOW}[aviso]${NC} %s\n" "$1"
}

echo_error() {
  printf "${RED}[erro]${NC} %s\n" "$1" >&2
}

# 1. Verifica se o Python 3.9+ está disponível
echo_info "Verificando Python..."
if ! command -v python >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  echo_error "Python não encontrado. Por favor, instale Python 3.9 ou superior."
  exit 1
fi

PY_CMD="python3"
command -v python >/dev/null 2>&1 && PY_CMD="python"

PY_VERSION="$($PY_CMD -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
echo_success "Python $PY_VERSION encontrado."

# 2. Verifica se uv está disponível, se não tenta instalar
echo_info "Verificando uv (gerenciador de pacotes Python)..."
if ! command -v uv >/dev/null 2>&1; then
  echo_warn "uv não encontrado. Instalando..."
  if command -v curl >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
  else
    echo_error "curl não encontrado. Instale uv manualmente: https://github.com/astral-sh/uv"
    exit 1
  fi
fi
echo_success "uv instalado/disponível."

# 3. Cria o ambiente virtual se não existir
VENV_DIR="$PROJECT_ROOT/.venv"
if [ ! -d "$VENV_DIR" ]; then
  echo_info "Criando ambiente virtual em $VENV_DIR..."
  uv venv "$VENV_DIR"
  echo_success "Ambiente virtual criado."
fi

# 4. Ativa o ambiente virtual
. "$VENV_DIR/bin/activate"
echo_success "Ambiente virtual ativado."

# 5. Sincroniza dependências
echo_info "Sincronizando dependências de pyproject.toml..."
if ! uv sync --locked; then
  echo_warn "Falha ao sincronizar com --locked. Tentando sem --locked..."
  uv sync || {
    echo_error "Falha ao sincronizar dependências."
    exit 1
  }
fi
echo_success "Dependências sincronizadas."

# 6. Detecta o shell do usuário e oferece integração
SHELL_NAME=$(basename "$SHELL")
echo_info "Shell detectado: $SHELL_NAME"

case "$SHELL_NAME" in
  bash|zsh|sh)
    echo_info "Para carregar o ambiente automaticamente em $SHELL_NAME, adicione ao seu ~/.${SHELL_NAME}rc:"
    echo ""
    echo "  . '$PROJECT_ROOT/scripts/env.sh'"
    echo ""
    ;;
  fish)
    echo_info "Para carregar o ambiente automaticamente em fish, adicione ao seu ~/.config/fish/config.fish:"
    echo ""
    echo "  source '$PROJECT_ROOT/scripts/env.fish'"
    echo ""
    ;;
  *)
    echo_warn "Shell não suportado diretamente: $SHELL_NAME"
    echo_info "Você pode executar manualmente: . '$PROJECT_ROOT/scripts/env.sh'"
    ;;
esac

# 7. Oferece configuração de armazenamento remoto
echo ""
echo_info "Configurando armazenamento remoto (opcional)..."
echo "Tipos suportados:"
echo "  - none (padrão)"
echo "  - gdrive (Google Drive)"
echo "  - dropbox"
echo "  - s3 (AWS S3)"
echo "  - gcp (Google Cloud Storage)"
echo "  - azure (Azure Storage)"
echo "  - r2 (Cloudflare R2)"
echo ""

# Verifica se rclone está instalado
if ! command -v rclone >/dev/null 2>&1; then
  echo_warn "rclone não está instalado. Para usar armazenamento remoto:"
  echo "  Linux/macOS: curl https://rclone.org/install.sh | sudo bash"
  echo "  ou instale via seu gerenciador de pacotes (apt, brew, etc.)"
else
  echo_success "rclone disponível."
  echo_info "Para configurar um novo remote, execute: rclone config"
  echo_info "Remotes configurados:"
  rclone listremotes || echo "  (nenhum configurado)"
fi

echo ""
echo_success "Instalação concluída!"
echo ""
echo_info "Próximos passos:"
echo "  1. Para executar a aplicação: ./scripts/run.sh"
echo "  2. Para usar Cloudflare Tunnel: ./scripts/run.sh --cloudflare"
echo "  3. Para configurar seu shell, execute:"
echo "     . scripts/env.sh (bash/zsh/sh)"
echo "     source scripts/env.fish (fish)"
echo ""
echo_info "Para mais informações sobre integração de remotes, veja:"
echo "  docs/Integra_remote-storage.md"
echo ""
