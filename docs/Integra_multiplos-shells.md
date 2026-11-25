# Playbook de integração com o Shell desejado

Sim, dá para centralizar tudo dentro da pasta `scripts/` do projeto e fazer com que cada shell (`bash`, `zsh`, `fish`) ou o próprio `scripts/run.sh` carregue o ambiente, valide os requisitos, atualize dependências pelo `.toml` se necessário e inicie a aplicação.

Há um detalhe importante de execução: **se você rodar `./scripts/run.sh` diretamente como um subshell, o `source .venv/bin/activate` e alterações de `PATH` valem apenas dentro do script**, não ficam persistidos no terminal depois que ele encerra. Para o ambiente persistir no shell atual, o script precisa ser **sourced** (`. scripts/env.sh` ou `source scripts/env.sh`) ou o `scripts/run.sh` deve rodar a aplicação no final dentro do ambiente já preparado.

---

## 1. Estrutura recomendada na pasta do projeto

```text
/home/jack/github/__rag_agentic/rag-chatbot/
├── pyproject.toml
├── .venv/
└── scripts/
    ├── env.sh      # Base POSIX (sh / bash / zsh): PATH, DMAgentics, .venv, check de .toml
    ├── env.fish    # Específico para fish: PATH, DMAgentics, .venv, check de .toml
    └── run.sh      # Carrega o ambiente, valida requisitos, atualiza se mudou .toml e sobe o app

```

---

## 2. `scripts/env.sh` (para `sh`, `bash`, `zsh` e chamado pelo `run.sh`)

```sh
#!/usr/bin/env sh

# Descobre a raiz do projeto mesmo se o script for chamado de outra pasta
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# 1. Variáveis e PATH do DMAgentics + ChatBotUI
[ -f "$HOME/.config/dmagentics/path.sh" ] && . "$HOME/.config/dmagentics/path.sh"
export PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"

# 2. Ativa o ambiente virtual Python 3.13
VENV_DIR="$PROJECT_ROOT/.venv"
if [ -z "$VIRTUAL_ENV" ] && [ -f "$VENV_DIR/bin/activate" ]; then
  . "$VENV_DIR/bin/activate"
fi

# 3. Atualiza dependências apenas se o pyproject.toml mudou
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
      uv pip install -e "$PROJECT_ROOT" && printf '%s\n' "$CURRENT_HASH" > "$HASH_FILE"
    else
      pip install -e "$PROJECT_ROOT" && printf '%s\n' "$CURRENT_HASH" > "$HASH_FILE"
    fi
  fi
}

```

---

## 3. `scripts/env.fish` (para `fish`)

```fish
set -l script_dir (status dirname)
set -g PROJECT_ROOT (realpath "$script_dir/..")

if test -f "$HOME/.config/dmagentics/path.sh"
  for line in (bash -c '[ -f "$HOME/.config/dmagentics/path.sh" ] && . "$HOME/.config/dmagentics/path.sh" && env')
    set -l parts (string split -m 1 "=" -- $line)
    if test (count $parts) -eq 2
      set -gx $parts[1] $parts[2]
    end
  end
end

set -gx PATH "$HOME/local/bin" "$HOME/.local/bin" $PATH

set -l venv_dir "$PROJECT_ROOT/.venv"
if test -z "$VIRTUAL_ENV"; and test -f "$venv_dir/bin/activate.fish"
  source "$venv_dir/bin/activate.fish"
end

function sync_toml_if_changed
  set -l toml_file "$PROJECT_ROOT/pyproject.toml"
  set -l hash_file "$venv_dir/.toml.sha256"
  test -f "$toml_file"; or return 0
  command -q sha256sum; or return 0

  mkdir -p "$venv_dir"
  set -l current_hash (sha256sum "$toml_file" | awk '{print $1}')
  set -l saved_hash ""
  if test -f "$hash_file"
    set saved_hash (cat "$hash_file")
  end

  if test "$current_hash" != "$saved_hash"
    echo "[env] Alteração detectada em pyproject.toml. Atualizando ambiente..."
    if command -q uv
      uv pip install -e "$PROJECT_ROOT"; and echo "$current_hash" > "$hash_file"
    else
      pip install -e "$PROJECT_ROOT"; and echo "$current_hash" > "$hash_file"
    end
  end
end

```

---

## 4. `scripts/run.sh` (carrega ambiente, valida requisitos, atualiza pelo `.toml` e inicia a app)

```sh
#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Carrega variáveis e .venv
. "$SCRIPT_DIR/env.sh"

# Valida requisitos mínimos do ambiente
if ! command -v python >/dev/null 2>&1; then
  echo "[erro] Python não encontrado no PATH." >&2
  exit 1
fi

PY_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
if [ "$PY_VERSION" != "3.13" ]; then
  echo "[aviso] Esperado Python 3.13, encontrado $PY_VERSION." >&2
fi

# Sincroniza dependências se pyproject.toml mudou
sync_toml_if_changed

# Troca para a raiz do projeto e inicia a aplicação
# (ajuste o comando abaixo para o entrypoint real do seu projeto)
cd "$PROJECT_ROOT"
exec python -m chatbot

```

Dê permissão de execução com `chmod +x scripts/run.sh scripts/env.sh` e, nos profiles do seu shell (`~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`), você pode apenas chamar o script correspondente quando estiver na pasta do projeto.

---

## 5. Como testar e validar

1. **Teste o script de ambiente diretamente:** 15 seg.
No terminal, rode `. scripts/env.sh` (em `bash`/`zsh`/`sh`) ou `source scripts/env.fish` (em `fish`).
*Verification:* `echo "$VIRTUAL_ENV"` mostra `/home/jack/github/__rag_agentic/rag-chatbot/.venv` e `which python` aponta para dentro do `.venv`.

2. **Teste a validação e o update via .toml:** 30 seg.
Altere o `pyproject.toml` e execute `./scripts/run.sh`.
*Verification:* O script valida o Python, exibe `[env] Alteração detectada em pyproject.toml. Atualizando ambiente...` e inicia o comando final sem abortar com `set -e`.
