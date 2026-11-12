#!/bin/bash
# SHE SHIELD - Start Both Local SQLite Backend (8080) & Website Frontend (3000)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

python3 -u "$DIR/server/local_sqlite_server.py" &
API_PID=$!

cleanup() {
  echo ""
  echo "Stopping SHE SHIELD servers..."
  kill $API_PID 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

sleep 1
python3 -u "$DIR/server/web_frontend_server.py"
cleanup
