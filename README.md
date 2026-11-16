# PrivateGPT on Railway

A one-click Railway template for [PrivateGPT](https://github.com/zylon-ai/private-gpt), the open-source API layer from Zylon for private AI apps: document ingestion, retrieval with citations, agentic RAG, tools and MCP connectors, behind a Claude-style Messages API, plus a built-in workbench UI.

## What it deploys

| Service | Built from | Public | Volume |
|---|---|---|---|
| **PrivateGPT** | [`privategpt/`](privategpt) — `zylonai/private-gpt:1.0.1@sha256:d4ae47c8…` | yes (`/ui/` workbench, API, `/docs`) | `/home/worker/app/local_data` (vector store, documents, skills database) |
| **Ollama** | [`ollama/`](ollama) — `ollama/ollama:0.40.16@sha256:910d0d81…` | no (private network only) | `/root/.ollama` (models) |

On its first start, Ollama downloads `qwen3:1.7b` (chat, about 1.4 GB) and `mxbai-embed-large:335m` (embeddings, about 670 MB). PrivateGPT answers its health check and waits until both models are listed, then starts. Nothing is sent to an outside AI provider.

The API is protected by PrivateGPT's built-in HTTP Basic auth. The username is `admin` and the password is generated at deploy time (`PRIVATEGPT_PASSWORD` on the PrivateGPT service). PrivateGPT refuses to start without a password.

### Wrapper changes to the official images

- `privategpt/settings-railway.yaml` (profile `railway`) switches on Basic auth; `start.sh` builds the expected `Authorization` header from `PRIVATEGPT_USERNAME` and `PRIVATEGPT_PASSWORD`.
- `privategpt/wait_for_models.py` serves `/health` while the model server is still downloading, so a first deploy doesn't crash-loop on "Default model not found".
- The workbench's default API URL is patched to use the page's own origin. Upstream rewrites it to `http://127.0.0.1:<port>`, which a browser can't reach behind a public domain.
- CORS is off by default (`PGPT_CORS_ENABLED=false`); server-side API clients are unaffected.
- `ollama/start.sh` starts `ollama serve` on `[::]:11434`, pulls the configured models and sets each model's `num_thread` to fit the container's CPU quota. Without that, llama.cpp starts one thread per host core (48 on Railway's hosts), gets throttled, and a single embedding call can take minutes.

## Variables

| Service | Variable | Default | Purpose |
|---|---|---|---|
| PrivateGPT | `PRIVATEGPT_USERNAME` | `admin` | Basic auth username for the API and workbench |
| PrivateGPT | `PRIVATEGPT_PASSWORD` | generated | Basic auth password |
| PrivateGPT | `OPENAI_API_BASE` | `http://${{Ollama.RAILWAY_PRIVATE_DOMAIN}}:11434/v1` | Any OpenAI-compatible server |
| PrivateGPT | `PGPT_LLM_DEFAULT` | `${{Ollama.OLLAMA_LLM_MODEL}}` | Default chat model |
| PrivateGPT | `PGPT_EMBEDDING_DEFAULT` | `${{Ollama.OLLAMA_EMBEDDING_MODEL}}` | Default embedding model |
| Ollama | `OLLAMA_LLM_MODEL` | `qwen3:1.7b` | Chat model pulled on start |
| Ollama | `OLLAMA_EMBEDDING_MODEL` | `mxbai-embed-large:335m` | Embedding model pulled on start (1024 dimensions, matches PrivateGPT's default) |
| Ollama | `OLLAMA_CONTEXT_LENGTH` | `16384` | Context window Ollama gives each model |
| Ollama | `OLLAMA_NUM_THREADS` | not set | Optional. CPU threads per model; by default the CPU quota minus 2, at most 16 |

Use explicit model tags (`name:tag`): PrivateGPT matches model ids exactly as Ollama lists them, so `mxbai-embed-large` (listed as `mxbai-embed-large:latest`) would not be found.

To use OpenAI or another hosted provider instead, set `OPENAI_API_BASE`, `OPENAI_API_KEY`, `PGPT_LLM_DEFAULT` and `PGPT_EMBEDDING_DEFAULT` (and `PGPT_EMBED_DIM` if the embedding size isn't 1024) on PrivateGPT, then remove the Ollama service. See [PrivateGPT's docs](https://docs.privategpt.dev/).

## Using it

1. Open the PrivateGPT domain at `/ui/`.
2. In the guided setup, keep the base URL (your Railway domain), open **Authentication (HTTP Basic Auth)** and enter `admin` and the `PRIVATEGPT_PASSWORD` from the PrivateGPT service's Variables tab, then click **Save and check**.
3. Upload documents and chat. Answers about your documents come with citations.
4. API clients send the same credentials as HTTP Basic auth, for example `curl -u admin:PASSWORD https://YOUR-DOMAIN/v1/models`.

## Updates

Railway notifies everyone who deployed this template when a change is merged to this repo's `main` branch. Each change is listed in [CHANGELOG.md](CHANGELOG.md), breaking changes first. Pins are bumped only after the new upstream release is tested on Railway.

## License

The wrapper files in this repo are MIT. PrivateGPT is Apache-2.0 (Zylon); Ollama is MIT.
