#!/bin/sh
# Start PrivateGPT on Railway with its API behind HTTP Basic auth.
set -eu

PRIVATEGPT_USERNAME="${PRIVATEGPT_USERNAME:-admin}"
if [ -z "${PRIVATEGPT_PASSWORD:-}" ]; then
  echo "PRIVATEGPT_PASSWORD is empty. Refusing to start PrivateGPT without a login." >&2
  exit 1
fi
PGPT_AUTH_HEADER="Basic $(printf '%s:%s' "$PRIVATEGPT_USERNAME" "$PRIVATEGPT_PASSWORD" | base64 | tr -d '\n')"
export PGPT_AUTH_HEADER

# Ollama and many self-hosted servers ignore the key, but the OpenAI client wants one.
export OPENAI_API_KEY="${OPENAI_API_KEY:-not-needed}"

mkdir -p /home/worker/app/local_data

# PrivateGPT stops at boot if its default models can't be found. On a first
# deploy the Ollama service is still downloading them, so wait here (answering
# /health meanwhile) instead of crash-looping.
if [ "${PGPT_WAIT_FOR_MODELS:-true}" = "true" ]; then
  python3 /home/worker/app/railway/wait_for_models.py || true
fi

exec private-gpt serve --host "${PGPT_BIND_HOST:-0.0.0.0}" --port "${PORT:-8080}"
