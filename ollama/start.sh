#!/bin/sh
# Start Ollama, then make sure PrivateGPT's chat and embedding models are downloaded.
set -eu

ollama serve &
SERVE_PID=$!
trap 'kill -TERM "$SERVE_PID" 2>/dev/null; wait "$SERVE_PID"' TERM INT

i=0
until ollama list >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 60 ]; then echo "ollama serve did not start" >&2; exit 1; fi
  if ! kill -0 "$SERVE_PID" 2>/dev/null; then echo "ollama serve exited" >&2; exit 1; fi
  sleep 1
done

for model in ${OLLAMA_LLM_MODEL:-} ${OLLAMA_EMBEDDING_MODEL:-} ${OLLAMA_EXTRA_MODELS:-}; do
  echo "[railway] pulling $model"
  n=0
  until ollama pull "$model"; do
    n=$((n + 1))
    if [ "$n" -ge 5 ]; then echo "[railway] could not pull $model, continuing" >&2; break; fi
    sleep 10
  done
done
echo "[railway] models ready"

wait "$SERVE_PID"
