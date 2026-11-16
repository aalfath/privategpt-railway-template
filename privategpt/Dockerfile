# PrivateGPT for Railway: the official image, pinned by version and digest.
FROM zylonai/private-gpt:1.0.1@sha256:d4ae47c82f87be03beb400d351d60e40890e3bcce131083d0f26b7604c3cacf7

WORKDIR /home/worker/app

# The server rewrites the workbench's default API URL to http://127.0.0.1:<port>,
# which a browser can't reach behind a public domain. Change the line so the
# rewrite no longer matches and the UI keeps using its own origin.
RUN grep -q 'const DEFAULT_BASE_URL = window.location.origin === "null"' ui/index.html \
 && sed -i 's/const DEFAULT_BASE_URL = window.location.origin === "null"/const DEFAULT_BASE_URL = (window.location.origin === "null")/' ui/index.html \
 && grep -q 'const DEFAULT_BASE_URL = (window.location.origin === "null")' ui/index.html

COPY settings-railway.yaml /home/worker/app/settings-railway.yaml
COPY wait_for_models.py /home/worker/app/railway/wait_for_models.py
COPY start.sh /home/worker/app/railway/start.sh
RUN chmod +x /home/worker/app/railway/start.sh

ENV PGPT_PROJECT_ROOT=/home/worker/app \
    PGPT_SETTINGS_FOLDER=/home/worker/app \
    PGPT_PROFILES=railway \
    PGPT_CORS_ENABLED=false \
    PORT=8080

EXPOSE 8080
ENTRYPOINT ["/home/worker/app/railway/start.sh"]
