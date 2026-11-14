#!/bin/bash
# SHE SHIELD - Start Both Backend (8080) & Website Frontend (3000)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ -f "$DIR/../.venv/bin/python" ]; then
  PYTHON="$DIR/../.venv/bin/python"
elif [ -f "$DIR/.venv/bin/python" ]; then
  PYTHON="$DIR/.venv/bin/python"
else
  PYTHON="python3"
fi

$PYTHON -u "$DIR/server/local_sqlite_server.py" &
API_PID=$!

cleanup() {
  echo ""
  echo "Stopping SHE SHIELD servers..."
  kill $API_PID 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

sleep 1
$PYTHON -u "$DIR/server/web_frontend_server.py"
cleanup
