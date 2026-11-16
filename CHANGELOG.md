# Changelog

## 1.0.1-2 (2026-11-16)

- README: Deploy on Railway button for the published template (`privategpt`). No change to the services.

## 1.0.1-1 (2026-11-16)

First release.

- PrivateGPT 1.0.1 (`zylonai/private-gpt:1.0.1@sha256:d4ae47c82f87be03beb400d351d60e40890e3bcce131083d0f26b7604c3cacf7`) with Basic auth on, CORS off, a model wait step and the workbench base-URL fix.
- Ollama 0.40.16 (`ollama/ollama:0.40.16@sha256:910d0d8107b538fb0894e63163eb195de0cc7aefcbc666dc62d3b18f71124592`), pulling `qwen3:1.7b` and `mxbai-embed-large:335m` on start, with each model's `num_thread` capped to the container's CPU quota.
