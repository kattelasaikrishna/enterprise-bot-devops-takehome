import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket

CONFIG_DIR = Path("/etc/demo-config")


def read_config(name, default):
    """Read a mounted ConfigMap value, falling back to an environment variable."""
    try:
        return (CONFIG_DIR / name).read_text(encoding="utf-8").strip()
    except (FileNotFoundError, OSError):
        return os.environ.get(name, default)


class RequestHandler(BaseHTTPRequestHandler):
    def send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/healthz":
            self.send_json(200, {"status": "ok"})
            return

        if self.path == "/":
            self.send_json(
                200,
                {
                    "app": read_config(
                        "APP_NAME",
                        os.environ.get("APP_NAME", "demo-service"),
                    ),
                    "version": read_config(
                        "VERSION",
                        os.environ.get("VERSION", "1.0.0"),
                    ),
                    "pod": socket.gethostname(),
                },
            )
            return

        self.send_json(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        print(json.dumps({
            "client": self.client_address[0],
            "message": fmt % args,
        }))


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), RequestHandler)
    print(f"Starting HTTP server on port {port}", flush=True)
    server.serve_forever()
