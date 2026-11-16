#!/bin/sh
# Start Ollama, then make sure PrivateGPT's chat and embedding models are downloaded.
set -eu

# llama.cpp starts one thread per host core (48 on Railway's hosts), not per
# core the container may use. Above the container's CPU quota the threads get
# throttled and a single embedding call can take minutes. Cap the threads with
# each model's num_thread parameter: OLLAMA_NUM_THREADS, else the CPU quota
# minus 2, at most 16.
cpu_quota() {
  if [ -r /sys/fs/cgroup/cpu.max ]; then
    read -r quota period < /sys/fs/cgroup/cpu.max || true
    if [ -n "${quota:-}" ] && [ "$quota" != "max" ] && [ -n "${period:-}" ]; then
      echo $(( (quota + period - 1) / period ))
      return
    fi
  fi
  nproc
}
if [ -n "${OLLAMA_NUM_THREADS:-}" ]; then
  THREADS="$OLLAMA_NUM_THREADS"
else
  THREADS=$(( $(cpu_quota) - 2 ))
  [ "$THREADS" -gt 16 ] && THREADS=16
  [ "$THREADS" -lt 1 ] && THREADS=1
fi
echo "[railway] CPU quota $(cpu_quota), using $THREADS threads per model"

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

MODELFILE=$(mktemp)
for model in ${OLLAMA_LLM_MODEL:-} ${OLLAMA_EMBEDDING_MODEL:-} ${OLLAMA_EXTRA_MODELS:-}; do
  echo "[railway] pulling $model"
  n=0
  until ollama pull "$model" >/dev/null; do
    n=$((n + 1))
    if [ "$n" -ge 5 ]; then echo "[railway] could not pull $model, continuing" >&2; break; fi
    sleep 10
  done
  if ollama show "$model" >/dev/null 2>&1; then
    printf 'FROM %s\nPARAMETER num_thread %s\n' "$model" "$THREADS" > "$MODELFILE"
    ollama create "$model" -f "$MODELFILE" >/dev/null && echo "[railway] $model ready (num_thread $THREADS)"
  fi
done
rm -f "$MODELFILE"
echo "[railway] models ready"

wait "$SERVE_PID"
