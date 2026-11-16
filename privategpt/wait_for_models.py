"""Wait until the model server lists PrivateGPT's default models.

While waiting, answer GET /health with 200 on $PORT so Railway's health check
passes during a first deploy, when Ollama is still downloading models.
Gives up after PGPT_WAIT_TIMEOUT seconds (default 1800) and lets PrivateGPT start anyway.
"""
import json
import os
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import socket

base = os.environ.get("OPENAI_API_BASE", "https://api.openai.com/v1").rstrip("/")
emb_base = (os.environ.get("OPENAI_EMBEDDING_API_BASE") or base).rstrip("/")
key = os.environ.get("OPENAI_API_KEY", "")
emb_key = os.environ.get("OPENAI_EMBEDDING_API_KEY") or key
wanted = [
    (base, key, os.environ.get("PGPT_LLM_DEFAULT", "")),
    (emb_base, emb_key, os.environ.get("PGPT_EMBEDDING_DEFAULT", "")),
]
timeout = int(os.environ.get("PGPT_WAIT_TIMEOUT", "1800"))
port = int(os.environ.get("PORT", "8080"))


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        code = 200 if self.path.startswith("/health") else 503
        body = json.dumps({"status": "starting" if code == 200 else "waiting for models"}).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


class DualStackServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6
    allow_reuse_address = True

    def server_bind(self):
        try:
            self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        except OSError:
            pass
        super().server_bind()


def list_models(api_base, api_key):
    req = urllib.request.Request(api_base + "/models")
    if api_key:
        req.add_header("Authorization", "Bearer " + api_key)
    with urllib.request.urlopen(req, timeout=10) as r:
        data = json.load(r)
    ids = set()
    for m in data.get("data", []):
        ids.add(m.get("id", ""))
    return ids


def ready():
    for api_base, api_key, model in wanted:
        if not model:
            continue
        try:
            ids = list_models(api_base, api_key)
        except Exception as e:
            print(f"[railway] model server {api_base} not ready: {e}", flush=True)
            return False
        # PrivateGPT matches model ids exactly, so do the same here.
        if model not in ids:
            hint = ""
            if model + ":latest" in ids:
                hint = f" (the server lists '{model}:latest': use that exact id)"
            print(f"[railway] waiting for model '{model}' on {api_base}{hint}", flush=True)
            return False
    return True


def main():
    if ready():
        return 0
    try:
        server = DualStackServer(("::", port), Handler)
    except OSError:
        server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    deadline = time.time() + timeout
    try:
        while time.time() < deadline:
            time.sleep(10)
            if ready():
                print("[railway] models are available, starting PrivateGPT", flush=True)
                return 0
        print("[railway] gave up waiting for models, starting PrivateGPT anyway", flush=True)
        return 0
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    sys.exit(main())
