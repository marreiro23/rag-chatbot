# Integrando remote storage ao projeto

Para oferecer ao operador armazenamento remoto via **Rclone** (`gdrive`, `dropbox`, `s3` na AWS ou GCP/GCS, `azureblob` / Azure Storage Account e `r2` / Cloudflare R2 — note que no Cloudflare é **R2**, não R3) dentro do projeto, você pode adicionar a seleção do provedor/remote e do modo de montagem (`host` com bind mount ou `docker-volume` com o plugin do Rclone) nos scripts em `scripts/` e no `docker-compose.yml`.

> Nota: No Rclone, o bucket/objeto da Cloudflare chama-se **R2** (`type = s3` com endpoint do Cloudflare R2), o Google Cloud Storage costuma ser configurado como `s3` (interoperabilidade) ou `google cloud storage`, e o Azure Storage Account usa o backend `azureblob`.

## 1. Como integrar na estrutura existente (`scripts/` + Docker Compose)

Adicione variáveis de configuração no `scripts/env.sh` e `scripts/env.fish` para que o operador escolha qual remote usar (vazio = armazenamento local padrão) e qual estratégia prefere (`host` ou `volume`):

```sh
# Em scripts/env.sh (adicione ao final)
REMOTE_STORAGE_BACKEND="${REMOTE_STORAGE_BACKEND:-none}"   # none | gdrive | dropbox | s3 | gcp | azure | r2
REMOTE_STORAGE_NAME="${REMOTE_STORAGE_NAME:-}"             # Ex.: gdrive, dropbox, aws-s3, gcp-gcs, azure-sa, cf-r2
REMOTE_STORAGE_PATH="${REMOTE_STORAGE_PATH:-}"             # Ex.: minha-pasta ou bucket/prefixo
REMOTE_MOUNT_MODE="${REMOTE_MOUNT_MODE:-host}"             # host | volume
REMOTE_HOST_MOUNT_DIR="${REMOTE_HOST_MOUNT_DIR:-/mnt/remote-storage}"

mount_remote_if_enabled() {
  [ "$REMOTE_STORAGE_BACKEND" = "none" ] && return 0

  if [ -z "$REMOTE_STORAGE_NAME" ]; then
    echo "[erro] Defina REMOTE_STORAGE_NAME para usar armazenamento remoto ($REMOTE_STORAGE_BACKEND)." >&2
    return 1
  fi

  case "$REMOTE_MOUNT_MODE" in
    host)
      command -v rclone >/dev/null 2>&1 || { echo "[erro] rclone não instalado no host." >&2; return 1; }
      mkdir -p "$REMOTE_HOST_MOUNT_DIR"
      if ! mountpoint -q "$REMOTE_HOST_MOUNT_DIR" 2>/dev/null; then
        echo "[storage] Montando ${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH} em $REMOTE_HOST_MOUNT_DIR..."
        rclone mount "${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH}" "$REMOTE_HOST_MOUNT_DIR" \
          --vfs-cache-mode full \
          --allow-other \
          --daemon
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

```

E chame `mount_remote_if_enabled` dentro do `scripts/run.sh` logo após `sync_toml_if_changed`.

---

## 2. Configurando os remotes no Rclone para cada provedor

Ao rodar `rclone config` no host (e depois copiar `~/.config/rclone/rclone.conf` para `/var/lib/docker-plugins/rclone/config/rclone.conf` caso use a **Opção 2**), os provedores solicitados ficam mapeados assim:

| Provedor pedido | Tipo no `rclone config` | Exemplo de `remote` no volume/mount | Observação para o operador |
| --- | --- | --- | --- |
| **Google Drive (`gdrive`)** | `drive` | `gdrive:rag-chatbot/dados` | Requer autenticação OAuth no navegador ou token copiado. |
| **Dropbox (`dropbox`)** | `dropbox` | `dropbox:rag-chatbot/dados` | Requer autorização OAuth da conta/app do Dropbox. |
| **AWS S3 (`s3`)** | `s3` (`provider = AWS`) | `aws-s3:meu-bucket/dados` | Use `env_auth = true` ou chaves `access_key_id` / `secret_access_key` e `region`. |
| **GCP Storage (`gcp`)** | `google cloud storage` ou `s3` (`provider = GCS`) | `gcp-gcs:meu-bucket/dados` | Com GCS nativo, use `service_account_file` apontando para o JSON da service account. |
| **Azure Storage Account (`azure`)** | `azureblob` | `azure-sa:meu-container/dados` | Configure `account` e `key` (ou SAS token / MSI). |
| **Cloudflare R2 (`r2`)** | `s3` (`provider = Cloudflare`) | `cf-r2:meu-bucket-r2/dados` | Informe `access_key_id`, `secret_access_key` e o endpoint `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`. |

---

## 3. Exemplo no `docker-compose.yml` para as duas opções

Você pode manter ambos os padrões documentados no `docker-compose.yml` para o operador escolher conforme a infraestrutura:

```yaml
services:
  app:
    image: sua-imagem:latest
    volumes:
      # Opção 1: Bind mount de pasta montada no host via rclone mount
      - ${REMOTE_HOST_MOUNT_DIR:-/mnt/remote-storage}:/dados

      # Opção 2: Volume gerenciado pelo plugin rclone/docker-volume-rclone
      # - remote_data:/dados

# Necessário apenas se o operador usar a Opção 2 (plugin Docker do Rclone):
volumes:
  remote_data:
    driver: rclone
    driver_opts:
      remote: '${REMOTE_STORAGE_NAME}:${REMOTE_STORAGE_PATH}'
      allow_other: 'true'
      vfs_cache_mode: 'full'

```

> Dica: Se você usar `rclone mount ... --allow-other`, certifique-se de que `user_allow_other` esteja habilitado em `/etc/fuse.conf` no host Linux; caso contrário, o `rclone mount` pode falhar ao iniciar.

---

## 4. Como validar a integração

1. **Teste o remote diretamente com Rclone:** 20 seg.
Execute `rclone lsd <nome-do-remote>:` no terminal do host.
*Verification:* O comando lista os diretórios ou buckets remotos sem erro de autenticação ou permissão.


2. **Valide a montagem (Opção 1) ou o plugin (Opção 2):** 30 seg.
Para a Opção 1, rode `ls -la /mnt/remote-storage`; para a Opção 2, rode `docker plugin ls`.
*Verification:* Na Opção 1, os arquivos remotos aparecem na pasta local; na Opção 2, o plugin `rclone` aparece com `ENABLED = true`.


3. **Teste leitura e escrita através do contêiner:** 30 seg.
Crie um arquivo de teste em `/dados` dentro do contêiner e confira se ele aparece no provedor remoto.
*Verification:* O arquivo criado no contêiner sincroniza sem erros de permissão (`permission denied`) ou bloqueio de escrita.