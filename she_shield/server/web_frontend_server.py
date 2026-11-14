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
import sys
from functools import partial
from http.server import HTTPServer, SimpleHTTPRequestHandler
from socketserver import ThreadingMixIn

SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
if SERVER_DIR not in sys.path:
    sys.path.insert(0, SERVER_DIR)

import local_sqlite_server
from local_sqlite_server import SQLiteAPIHandler, init_db

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


class FlutterWebHandler(SQLiteAPIHandler, SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        if directory is None:
            directory = WEB_BUILD_DIR
        SimpleHTTPRequestHandler.__init__(self, *args, directory=directory, **kwargs)

    def _is_api(self):
        clean_path = self.path.split("?", 1)[0].split("#", 1)[0]
        return clean_path.startswith("/api/") or clean_path in ("/health", "/api/status")

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Evidence-Meta, Range")
        self.send_header("Access-Control-Expose-Headers", "Content-Disposition, X-Sha256-Hash, Accept-Ranges, Content-Range")
        self.send_header("Access-Control-Allow-Private-Network", "true")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_GET(self):
        if self._is_api():
            return SQLiteAPIHandler.do_GET(self)
        clean_path = self.path.split("?", 1)[0].split("#", 1)[0]
        if clean_path in ("/", ""):
            self.path = "/index.html"
        else:
            rel = clean_path.lstrip("/")
            full = os.path.join(WEB_BUILD_DIR, rel)
            if not os.path.exists(full):
                # SPA fallback for Flutter routing
                self.path = "/index.html"
        return SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        if self._is_api():
            return SQLiteAPIHandler.do_POST(self)
        self.send_error(405, "Method Not Allowed")

    def do_PUT(self):
        if self._is_api():
            return SQLiteAPIHandler.do_PUT(self)
        self.send_error(405, "Method Not Allowed")

    def do_DELETE(self):
        if self._is_api():
            return SQLiteAPIHandler.do_DELETE(self)
        self.send_error(405, "Method Not Allowed")

    def do_OPTIONS(self):
        if self._is_api():
            return SQLiteAPIHandler.do_OPTIONS(self)
        self.send_response(204)
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

    init_db()
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
