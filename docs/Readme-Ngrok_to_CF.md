# Migração Ngrok para Tunnel Cloudflare

- Mapeamento do fluxo atual, todas as referências a ngrok e os arquivos de ambiente antes de alterar o script.

> Read
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/scripts/run.sh"
}
> Search for `ngrok|NGROK|tunnel|cloudflare|CLOUDFLARE`
> Find files matching `{README*,*.md,.env*,docker-compose*.yml,docker-compose*.yaml,compose*.yml,com...`
> Read
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/scripts/install_extra.sh"
}
> Read
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/scripts/install.sh"
}
> read
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/docker-compose.yml"
}
> Read , lines 1 to 140
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/README.md",
  "view_range": [
    1,
    140
  ]
}
> Read
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/pyproject.toml"
}

Search for `ArgumentParser|--host|--port|launch\(`

Find files matching `src/**/*.py`

Find files matching `rag_chatbot/**/*.py`

> Read , lines 1 to 60
Completed with input: {
  "path": "/home/jack/github/__rag_agentic/rag-chatbot/rag_chatbot/__main__.py",
  "view_range": [
    1,
    60
  ]
}
> Ran terminal command: git --no-pager status --short && git --no-pager branch --show-current

- Search for `os\.getenv|environ|getenv|OPENAI|WANDB|dotenv`

- A migração será feita em três frentes: dependências de instalação, execução local (modo rápido ou túnel autenticado) e documentação/composição Docker.

- Edit , , , ,

- Search for `Ngrok|ngrok|NGROK`

Ran terminal command:

```bash
bash -n scripts/run.sh scripts/install_extra.sh scripts/install.sh
```

- Edit , , , ,

> Ran terminal command:

```python3
python3 - <<'PY'
import json
from pathlib import Path

path = Path('notebooks/kaggle.ipynb')
notebook = json.loads(path.read_text())

for cell in notebook['cells']:
    if cell.get('cell_type') != 'code':
        continue
    sources = cell.get('source', [])
    updated = []
    for source in sources:
        if 'ngrok config add-authtoken' in source:
            continue
        source = source.replace('run.sh --ngrok', 'run.sh --cloudflare')
        updated.append(source)
    cell['source'] = updated

path.write_text(json.dumps(notebook, ensure_ascii=False, indent=1) + '\n')
PY
python3 - <<'PY'
import yaml
with open('docker-compose.yml') as f:
    data = yaml.safe_load(f)
assert 'cloudflare' in data['services']
PY
```

```bash
bash -n scripts/run.sh scripts/install_extra.sh scripts/install.sh
```

- Antes da validação final, vou confirmar que não restaram referências ao ngrok e revisar o diff/resultados do notebook.

- Search for `Ngrok|ngrok|NGROK`

- Search for `Cloudflare|cloudflare|CLOUDFLARE`

Ran terminal command:

```docker-compose
docker-compose config >/tmp/rag-chatbot-compose-config.txt && bash -n scripts/run.sh scripts/install_extra.sh scripts/install.sh && git --no-pager diff --stat && git --no-pager diff -- scripts/run.sh scripts/install_extra.sh docker-compose.yml README.md .env.example
```

> Ran terminal command:

```python3
python3 -m json.tool notebooks/kaggle.ipynb >/dev/null && docker compose config >/dev/null && bash -n scripts/run.sh scripts/install_extra.sh scripts/install.sh
```

> Ran terminal command:

```git
git --no-pager status --short
```

> Read

- Completed with input: {
- "path": "/home/jack/github/__rag_agentic/rag-chatbot/scripts/run.sh"
- }

> Read

- Completed with input: {
- "path": "/home/jack/github/__rag_agentic/rag-chatbot/.env.example"
- }

## Migração concluída

### Script original

O `scripts/run.sh` original:

- Habilitava exclusivamente o túnel Ngrok com `--ngrok`.
- Verificava a dependência `uv`.
- Executava o aplicativo na porta `7860`.
- Inicializava o aplicativo e o Ngrok no mesmo processo.
- Não possuía limpeza automática dos processos.
- Não diferenciar a execução local da exposição pública.

### Nova arquitetura

A nova versão usa `cloudflared` e oferece dois modos:

- __Quick Tunnel__, sem conta ou token:

  ```bash
  bash ./scripts/run.sh --cloudflare
  ```

- __Túnel nomeado__, usando `CLOUDFLARE_TUNNEL_TOKEN`:

  ```bash
  CLOUDFLARE_TUNNEL_TOKEN="<token>" bash ./scripts/run.sh --cloudflare
  ```

O script agora:

- Mantém a execução normal sem túnel.
- Verifica `uv` e `cloudflared`.
- Aguarda a aplicação ficar disponível em `127.0.0.1:7860`.
- Expõe `127.0.0.1:7860` pelo Cloudflare.
- Finaliza o aplicativo e o túnel corretamente quando recebe `SIGINT`, `SIGTERM` ou `EXIT`.

## Dependências migradas

No `scripts/install_extra.sh`:

- Ollama continua sendo instalado.
- Ngrok foi removido completamente.
- `cloudflared` foi adicionado:
  - Linux via repositório oficial da Cloudflare.
  - macOS via Homebrew.
- `uv` continua responsável pelas dependências Python.
- O ambiente Python continua sincronizado com `uv sync --locked`.

## Ambiente e Docker

Foi criado `.env.example` com:

```dotenv
CLOUDFLARE_TUNNEL_TOKEN=
```

O Quick Tunnel não precisa dessa variável. O token só é necessário para usar um túnel persistente configurado no Cloudflare Zero Trust.

O `docker-compose.yml` recebeu um novo perfil opcional:

```bash
docker compose --profile cloudflare up --build
```

Nesse perfil:

- `app` continua na porta `7860`.
- `cloudflared` se conecta ao serviço `app` através da rede Docker.
- O túnel usa `http://app:7860`.
- O serviço inicia somente quando o perfil `cloudflare` é solicitado.

A `README.md` e o `notebooks/kaggle.ipynb` foram atualizados para remover todas as instruções e referências ao Ngrok.

## Validação realizada

Foram validados:

- Sintaxe Bash dos scripts.
- Sintaxe JSON do notebook Kaggle.
- Estrutura do Docker Compose.
- Ausência de referências residuais ao Ngrok no repositório.
