# Chat with multiple PDFs locally

![alt text](assets/demo.png)

## ?ï¿½ï¿½ Table of Contents

- [?ï¿½ï¿½ Table of Contents](#-table-of-contents)
- [â­ï¿½? Key Features](#?ï¿½?-key-features)
- [?ï¿½ï¿½ Idea (Experiment)](#-idea-experiment)
- [?ï¿½ï¿½ Setup](#-setup)
- [1. Kaggle (Recommended)](#1-kaggle-recommended)
- [2. Local](#2-local)
  - [2.1. Clone project](#21-clone-project)
  - [2.2 Install](#22-install)
  - [2.3 Run](#23-run)
  - [3. Go to: `http://0.0.0.0:7860/` or Cloudflare Tunnel link after setup completed](#3-go-to-http00007860-or-cloudflare-tunnel-link-after-setup-completed)
- [?ï¿½ï¿½ Star History](#-star-history)

## â­ï¿½? Key Features

- Easy to run on `Local` or `Kaggle` (new)
- Using any model from `Huggingface` and `Ollama`
- Process multiple PDF inputs.
- Chat with multiples languages (Coming soon).
- Simple UI with `Gradio`.

## ?ï¿½ï¿½ Idea (Experiment)

![RAG Flow](./assets/rag-flow.svg)

![Retriever](./assets/retriever.svg)

## ?ï¿½ï¿½ Setup

## 1. Kaggle (Recommended)

- Import [`notebooks/kaggle.ipynb`](notebooks/kaggle.ipynb) to Kaggle
- Cloudflare Quick Tunnels do not require an account or token.
- To use a persistent named tunnel, configure `CLOUDFLARE_TUNNEL_TOKEN` with the token from the Cloudflare Zero Trust dashboard.

## 2. Local

### 2.1. Clone project

```bash
git clone https://github.com/datvodinh/rag-chatbot.git
cd rag-chatbot
```

### 2.2 Install

#### 2.2.0 Install `uv` (once)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

> Make sure `~/.local/bin` (default install location) is on your `PATH`.

#### 2.2.1 Docker

```bash
docker compose up --build
```

#### 2.2.2 Using script (Ollama, Cloudflare Tunnel, Python package)

```bash
bash ./scripts/install_extra.sh
```

#### 2.2.3 Install manually

##### 1. `Ollama`

- MacOS, Window: [Download](https://ollama.com/)

- Linux

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

##### 2. `Cloudflare Tunnel`

- macOS: `brew install cloudflared`
- Linux: the installer in `scripts/install_extra.sh` configures the official `cloudflared` package repository.
- Manual installation: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/

##### 3. Install `rag_chatbot` Package

```bash
uv sync --locked
```

### 2.3 Run

```bash
bash ./scripts/run.sh
```

or

```bash
uv run python -m rag_chatbot --host localhost
```

- Using an ephemeral Cloudflare Quick Tunnel

```bash
bash ./scripts/run.sh --cloudflare
```

With Docker Compose:

```bash
docker compose --profile cloudflare up --build
```

The `cloudflare` Compose profile exposes the app through an ephemeral Quick Tunnel.
Docker's `cloudflared` container connects to `http://app:7860` on the Compose network.

- Using a named, persistent tunnel

```bash
cp .env.example .env
# Add CLOUDFLARE_TUNNEL_TOKEN to .env, then export it:
set -a
source .env
set +a
bash ./scripts/run.sh --cloudflare
```

Quick Tunnels require no Cloudflare account and generate a temporary `*.trycloudflare.com` URL.
A named tunnel requires a Cloudflare account, a configured tunnel, and a tunnel token.

### 3. Go to: `http://0.0.0.0:7860/` or the Cloudflare Tunnel link after setup completed

## ?ï¿½ï¿½ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=datvodinh/rag-chatbot&type=Date)](https://star-history.com/#datvodinh/rag-chatbot&Date)