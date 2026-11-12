#!/bin/bash
# SHE SHIELD - Start Local Website Frontend Server (port 3000)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ ! -d "build/web" ]; then
  echo "Building Flutter Web bundle first..."
  flutter build web
fi

python3 -u "$DIR/server/web_frontend_server.py"
