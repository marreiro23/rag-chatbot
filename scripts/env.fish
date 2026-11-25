#!/usr/bin/env fish
# Script de ambiente para Fish Shell - PATH, DMAgentics, .venv, check de .toml e storage remoto

set -l script_dir (status dirname)
set -gx PROJECT_ROOT (realpath "$script_dir/..")

# 1. Carrega PATH do DMAgentics se existir
if test -f "$HOME/.config/dmagentics/path.sh"
  for line in (bash -c '[ -f "$HOME/.config/dmagentics/path.sh" ] && . "$HOME/.config/dmagentics/path.sh" && env')
    set -l parts (string split -m 1 "=" -- $line)
    if test (count $parts) -eq 2
      set -gx $parts[1] $parts[2]
    end
  end
end

set -gx PATH "$HOME/local/bin" "$HOME/.local/bin" $PATH

# 2. Ativa o ambiente virtual Python
set -l venv_dir "$PROJECT_ROOT/.venv"
if test -z "$VIRTUAL_ENV"; and test -f "$venv_dir/bin/activate.fish"
  source "$venv_dir/bin/activate.fish"
end

# 3. Configuração de armazenamento remoto
set -gx REMOTE_STORAGE_BACKEND (set -q REMOTE_STORAGE_BACKEND; and echo $REMOTE_STORAGE_BACKEND; or echo "none")
set -gx REMOTE_STORAGE_NAME (set -q REMOTE_STORAGE_NAME; and echo $REMOTE_STORAGE_NAME; or echo "")
set -gx REMOTE_STORAGE_PATH (set -q REMOTE_STORAGE_PATH; and echo $REMOTE_STORAGE_PATH; or echo "")
set -gx REMOTE_MOUNT_MODE (set -q REMOTE_MOUNT_MODE; and echo $REMOTE_MOUNT_MODE; or echo "host")
set -gx REMOTE_HOST_MOUNT_DIR (set -q REMOTE_HOST_MOUNT_DIR; and echo $REMOTE_HOST_MOUNT_DIR; or echo "/mnt/remote-storage")

# 4. Função: Atualiza dependências apenas se o pyproject.toml mudou
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
      uv sync --locked; and echo "$current_hash" > "$hash_file"
    else if command -q pip
      pip install -e "$PROJECT_ROOT"; and echo "$current_hash" > "$hash_file"
    else
      echo "[erro] uv ou pip não encontrados." >&2
      return 1
    end
  end
end

# 5. Função: Monta armazenamento remoto se configurado
function mount_remote_if_enabled
  test "$REMOTE_STORAGE_BACKEND" = "none"; and return 0

  if test -z "$REMOTE_STORAGE_NAME"
    echo "[erro] Defina REMOTE_STORAGE_NAME para usar armazenamento remoto ($REMOTE_STORAGE_BACKEND)." >&2
    return 1
  end

  switch $REMOTE_MOUNT_MODE
    case host
      command -q rclone; or begin
        echo "[erro] rclone não instalado. Instale com: curl https://rclone.org/install.sh | sudo bash" >&2
        return 1
      end
      
      mkdir -p "$REMOTE_HOST_MOUNT_DIR"
      if not mountpoint -q "$REMOTE_HOST_MOUNT_DIR" 2>/dev/null
        echo "[storage] Montando ${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH} em $REMOTE_HOST_MOUNT_DIR..."
        rclone mount "${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH}" "$REMOTE_HOST_MOUNT_DIR" \
          --vfs-cache-mode full \
          --allow-other \
          --daemon
        sleep 2
      end
    case volume
      echo "[storage] Modo volume selecionado: o Docker gerenciará o mount via plugin rclone."
    case '*'
      echo "[erro] REMOTE_MOUNT_MODE inválido: $REMOTE_MOUNT_MODE (use 'host' ou 'volume')." >&2
      return 1
  end
end

# 6. Função: Valida requisitos mínimos do sistema
function validate_requirements
  command -q python; or begin
    echo "[erro] Python não encontrado no PATH." >&2
    return 1
  end

  set -l py_version (python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  
  if not python -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null
    echo "[erro] Python 3.9+ necessário, encontrado $py_version." >&2
    return 1
  end

  echo "[ok] Python $py_version encontrado."
end
