#!/bin/bash
# SHE SHIELD - Start Local Website Frontend Server (port 3000)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ ! -d "build/web" ]; then
  echo "Building Flutter Web bundle first..."
  flutter build web
fi

if [ -f "$DIR/../.venv/bin/python" ]; then
  PYTHON="$DIR/../.venv/bin/python"
elif [ -f "$DIR/.venv/bin/python" ]; then
  PYTHON="$DIR/.venv/bin/python"
else
  PYTHON="python3"
fi

$PYTHON -u "$DIR/server/web_frontend_server.py"
