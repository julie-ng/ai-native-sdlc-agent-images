"""Offline provider/model routing check, not a real-model integration test.

Run inside either image with --network none and Python on stdin. The loopback
server accepts only a synthetic key and asserts the runtime-selected model.
"""
import http.server
import json
import os
import subprocess
import threading

requests = []


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        requests.append((self.path, self.headers.get("Authorization"), body))
        self.send_response(200)
        if body.get("stream"):
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            for delta, finish in [({"role": "assistant", "content": "RUNTIME_CONFIG_OK"}, None), ({}, "stop")]:
                chunk = {"id": "offline-test", "object": "chat.completion.chunk",
                         "created": 0, "model": "offline-test-model",
                         "choices": [{"index": 0, "delta": delta, "finish_reason": finish}]}
                self.wfile.write(("data: " + json.dumps(chunk) + "\n\n").encode())
            self.wfile.write(b"data: [DONE]\n\n")
            return
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({
            "id": "offline-test", "object": "chat.completion", "created": 0,
            "model": "offline-test-model",
            "choices": [{"index": 0, "message": {
                "role": "assistant", "content": "RUNTIME_CONFIG_OK",
            }, "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
        }).encode())

    def log_message(self, *args):
        pass


config = os.path.expanduser("~/.config/goose/config.yaml")
assert not os.path.exists(config), "test must start without config.yaml"
server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
env = dict(os.environ, GOOSE_PROVIDER="openai", GOOSE_MODEL="offline-test-model",
           OPENAI_API_KEY="offline-synthetic-key",
           OPENAI_HOST=f"http://127.0.0.1:{server.server_port}",
           GOOSE_TELEMETRY_ENABLED="false", GOOSE_MODE="auto")
try:
    result = subprocess.run(
        ["goose", "run", "--text", "Reply RUNTIME_CONFIG_OK", "--max-turns", "1"],
        env=env, text=True, capture_output=True, timeout=60,
    )
    print(result.stdout)
    print(result.stderr)
    assert result.returncode == 0, result.returncode
    assert requests, "no request reached the runtime-selected endpoint"
    for path, auth, body in requests:
        assert path == "/v1/chat/completions", path
        assert auth == "Bearer offline-synthetic-key"
        assert body["model"] == "offline-test-model", body["model"]
    assert "RUNTIME_CONFIG_OK" in result.stdout
    print("Runtime-only provider/model routing: PASS (offline mock; no real model).")
finally:
    server.shutdown()
