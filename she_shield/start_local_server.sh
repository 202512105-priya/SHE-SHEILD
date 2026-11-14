#!/bin/bash
# SHE SHIELD - Start Local SQLite Live Server
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR/server"
HOST_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "172.24.75.79")
echo "=========================================================="
echo "  SHE SHIELD - Local SQLite Live Database Server"
echo "=========================================================="
echo "Host Machine Wi-Fi IP: $HOST_IP"
echo "Starting Python SQLite Server on port 8080..."
echo ""
if [ -f "$DIR/../.venv/bin/python" ]; then
  PYTHON="$DIR/../.venv/bin/python"
elif [ -f "$DIR/.venv/bin/python" ]; then
  PYTHON="$DIR/.venv/bin/python"
else
  PYTHON="python3"
fi
$PYTHON local_sqlite_server.py
