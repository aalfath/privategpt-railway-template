# Ollama for the PrivateGPT template: the official image, pinned by version and digest.
FROM ollama/ollama:0.40.16@sha256:910d0d8107b538fb0894e63163eb195de0cc7aefcbc666dc62d3b18f71124592

COPY start.sh /railway/start.sh
RUN chmod +x /railway/start.sh

# Listen on IPv6 and IPv4 so Railway's private network can reach it.
ENV OLLAMA_HOST=[::]:11434 \
    OLLAMA_LLM_MODEL=qwen3:1.7b \
    OLLAMA_EMBEDDING_MODEL=mxbai-embed-large:335m \
    OLLAMA_CONTEXT_LENGTH=16384 \
    OLLAMA_KEEP_ALIVE=30m

EXPOSE 11434
ENTRYPOINT ["/railway/start.sh"]
