# Scripts de Instalação e Ambiente

Este diretório contém scripts para gerenciar o ambiente de desenvolvimento, dependências e integração com múltiplos shells e armazenamento remoto.

## Estrutura

```
scripts/
├── install.sh      # Script principal de instalação
├── run.sh          # Script para executar a aplicação
├── env.sh          # Carrega ambiente (POSIX: bash, zsh, sh)
├── env.fish        # Carrega ambiente (Fish shell)
└── README.md       # Este arquivo
```

## Requisitos

- **Python 3.9+** (versão recomendada: 3.13)
- **curl** (para instalar `uv` se necessário)
- **uv** (gerenciador de pacotes Python, instalado automaticamente se necessário)

Opcional:
- **rclone** (para suporte a armazenamento remoto)
- **cloudflared** (para Cloudflare Tunnel)

## 1. Instalação Inicial

Execute o script de instalação:

```bash
./scripts/install.sh
```

Este script irá:
1. ✅ Verificar Python 3.9+
2. ✅ Instalar `uv` se necessário
3. ✅ Criar ambiente virtual (`.venv`)
4. ✅ Sincronizar dependências de `pyproject.toml`
5. ✅ Sugerir integração com seu shell
6. ✅ Detectar e configurar `rclone` (opcional)

## 2. Executar a Aplicação

### Modo simples

```bash
./scripts/run.sh
```

### Com Cloudflare Tunnel

```bash
./scripts/run.sh --cloudflare
```

Isso irá:
- Validar o ambiente Python
- Sincronizar dependências se `pyproject.toml` mudou
- Montar armazenamento remoto se configurado
- Iniciar a aplicação

## 3. Integração com Shell

### Para Bash, Zsh ou Sh

Adicione ao arquivo `~/.bashrc`, `~/.zshrc` ou equivalente:

```bash
source /caminho/para/rag-chatbot/scripts/env.sh
```

### Para Fish

Adicione ao arquivo `~/.config/fish/config.fish`:

```fish
source /caminho/para/rag-chatbot/scripts/env.fish
```

Depois reabra o terminal ou execute:

```bash
# bash/zsh
source ~/.bashrc

# fish
source ~/.config/fish/config.fish
```

## 4. Variáveis de Ambiente

Os scripts de ambiente exportam as seguintes variáveis:

### Path e Ativação do venv

- `VIRTUAL_ENV`: Localização do ambiente virtual
- `PATH`: Inclui diretórios do `venv` e usuário

### Armazenamento Remoto

Configure via variáveis de ambiente:

```bash
export REMOTE_STORAGE_BACKEND="s3"           # none | gdrive | dropbox | s3 | gcp | azure | r2
export REMOTE_STORAGE_NAME="aws-s3"          # Nome do remote configurado no rclone
export REMOTE_STORAGE_PATH="meu-bucket/rag"  # Caminho dentro do remote
export REMOTE_MOUNT_MODE="host"              # host | volume
export REMOTE_HOST_MOUNT_DIR="/mnt/remote-storage"
```

## 5. Integração com Armazenamento Remoto

### Pré-requisito

Instale `rclone`:

```bash
# Linux/macOS
curl https://rclone.org/install.sh | sudo bash

# ou via gerenciador de pacotes
apt-get install rclone  # Debian/Ubuntu
brew install rclone     # macOS
```

### Configurar um Remote

```bash
rclone config
```

Escolha o tipo de provedor:

| Provedor | Tipo | Exemplo |
|----------|------|---------|
| Google Drive | `drive` | `gdrive:rag-chatbot/dados` |
| Dropbox | `dropbox` | `dropbox:rag-chatbot/dados` |
| AWS S3 | `s3` | `aws-s3:meu-bucket/dados` |
| Google Cloud Storage | `google cloud storage` | `gcp-gcs:meu-bucket/dados` |
| Azure Storage | `azureblob` | `azure-sa:meu-container/dados` |
| Cloudflare R2 | `s3` (Cloudflare) | `cf-r2:meu-bucket/dados` |

### Usar um Remote

Defina as variáveis de ambiente:

```bash
export REMOTE_STORAGE_BACKEND="s3"
export REMOTE_STORAGE_NAME="aws-s3"
export REMOTE_STORAGE_PATH="meu-bucket/rag-data"
export REMOTE_MOUNT_MODE="host"

# Depois execute:
./scripts/run.sh
```

Ou edite `.env` no raiz do projeto (se usar direnv ou similar):

```bash
REMOTE_STORAGE_BACKEND=s3
REMOTE_STORAGE_NAME=aws-s3
REMOTE_STORAGE_PATH=meu-bucket/rag-data
REMOTE_MOUNT_MODE=host
```

## 6. Sincronização Automática de Dependências

Os scripts detectam automaticamente quando `pyproject.toml` foi modificado e sincronizam dependências:

```bash
# Verifica o hash SHA256 de pyproject.toml
# Se mudou, executa: uv sync --locked
```

Para forçar sincronização:

```bash
source scripts/env.sh  # ou . scripts/env.sh
sync_toml_if_changed   # Força verificação
```

## 7. Validação do Ambiente

Para verificar se tudo está configurado corretamente:

```bash
# Ativa o ambiente
source scripts/env.sh

# Verifica Python
python --version

# Verifica ambiente virtual
echo $VIRTUAL_ENV

# Verifica pacotes instalados
pip list

# Se usar rclone, valida remotes
rclone listremotes
```

## 8. Troubleshooting

### "uv is required"

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"
```

### "Python not found"

Certifique-se que Python 3.9+ está instalado:

```bash
python3 --version  # ou python --version
```

### "Virtual environment activation failed"

Recrie o ambiente:

```bash
rm -rf .venv
./scripts/install.sh
```

### "rclone mount permission denied"

Enable `user_allow_other` no Linux:

```bash
sudo bash -c 'echo "user_allow_other" >> /etc/fuse.conf'
```

### "Module not found after sync"

Certifique-se que o ambiente virtual está ativado:

```bash
source scripts/env.sh
python -m chatbot
```

## 9. Variáveis de Ambiente do DMAgentics

Se você usar DMAgentics, o arquivo `~/.config/dmagentics/path.sh` é carregado automaticamente para incluir dependências extras.

## 10. Próximos Passos

- Veja [Integra_multiplos-shells.md](../docs/Integra_multiplos-shells.md) para mais detalhes de integração com shells
- Veja [Integra_remote-storage.md](../docs/Integra_remote-storage.md) para mais detalhes de armazenamento remoto
- Veja [Readme-Ngrok_to_CF.md](../docs/Readme-Ngrok_to_CF.md) para configurar Cloudflare Tunnel
