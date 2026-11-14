#!/usr/bin/env python3
"""
SHE SHIELD - Local Web Frontend Server
Serves the built Flutter web application (build/web) on port 3000.
Connects to the Local SQLite Live Server running on port 8080.
"""

import json
import mimetypes
import os
import socket
import urllib.request
import urllib.error
from functools import partial
from http.server import HTTPServer, SimpleHTTPRequestHandler
from socketserver import ThreadingMixIn

PORT = 3000
API_PORT = 8080
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_BUILD_DIR = os.path.join(PROJECT_DIR, "build", "web")

# Ensure proper MIME types for Flutter web assets
mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("application/javascript", ".js")
mimetypes.add_type("application/javascript", ".mjs")
mimetypes.add_type("application/manifest+json", ".webmanifest")


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


class FlutterWebHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def _is_api(self):
        clean_path = self.path.split("?", 1)[0].split("#", 1)[0]
        return clean_path.startswith("/api/") or clean_path in ("/health", "/api/status")

    def _proxy_to_backend(self, method):
        backend_url = f"http://127.0.0.1:{API_PORT}{self.path}"
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else None

        req = urllib.request.Request(backend_url, data=body, method=method)
        for header, val in self.headers.items():
            if header.lower() not in ("host", "content-length"):
                req.add_header(header, val)

        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        try:
            with opener.open(req, timeout=15) as resp:
                self.send_response(resp.status)
                for header, val in resp.getheaders():
                    if header.lower() not in ("transfer-encoding", "content-length"):
                        self.send_header(header, val)
                content = resp.read()
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for header, val in e.headers.items():
                if header.lower() not in ("transfer-encoding", "content-length"):
                    self.send_header(header, val)
            content = e.read()
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        except Exception as e:
            err_json = json.dumps({"error": f"Failed to reach backend API on port {API_PORT}: {e}"}).encode("utf-8")
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(err_json)))
            self.end_headers()
            self.wfile.write(err_json)

    def do_GET(self):
        if self._is_api():
            return self._proxy_to_backend("GET")
        clean_path = self.path.split("?", 1)[0].split("#", 1)[0]
        if clean_path in ("/", ""):
            self.path = "/index.html"
        else:
            rel = clean_path.lstrip("/")
            full = os.path.join(WEB_BUILD_DIR, rel)
            if not os.path.exists(full):
                # SPA fallback for Flutter routing
                self.path = "/index.html"
        return super().do_GET()

    def do_POST(self):
        if self._is_api():
            return self._proxy_to_backend("POST")
        self.send_error(405, "Method Not Allowed")

    def do_PUT(self):
        if self._is_api():
            return self._proxy_to_backend("PUT")
        self.send_error(405, "Method Not Allowed")

    def do_DELETE(self):
        if self._is_api():
            return self._proxy_to_backend("DELETE")
        self.send_error(405, "Method Not Allowed")

    def do_OPTIONS(self):
        if self._is_api():
            return self._proxy_to_backend("OPTIONS")
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()


def get_lan_ips():
    ips = []
    try:
        import subprocess
        out = subprocess.check_output(["ifconfig"]).decode("utf-8", errors="ignore")
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("inet ") and "127.0.0.1" not in line:
                parts = line.split()
                if len(parts) >= 2:
                    ip = parts[1]
                    if ip not in ips and not ip.startswith("169.254."):
                        ips.append(ip)
    except Exception:
        pass
    return ips


if __name__ == "__main__":
    if not os.path.isdir(WEB_BUILD_DIR):
        raise SystemExit(
            f"[Web Server] Build directory not found at {WEB_BUILD_DIR}.\n"
            f"Run 'flutter build web' inside {PROJECT_DIR} first."
        )

    handler = partial(FlutterWebHandler, directory=WEB_BUILD_DIR)
    httpd = ThreadedHTTPServer(("0.0.0.0", PORT), handler)
    lan_ips = get_lan_ips()

    print("=" * 65)
    print("  SHE SHIELD - Website Frontend Server Running!")
    print(f"  Serving:   {WEB_BUILD_DIR}")
    print(f"  Local URL: http://localhost:{PORT}")
    for ip in lan_ips:
        print(f"  Wi-Fi URL: http://{ip}:{PORT}")
    print(f"  API Sync:  port {API_PORT} (SQLite 3)")
    print("=" * 65)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[Web Server] Shutting down...")
        httpd.server_close()
