#!/bin/bash
# SHE SHIELD - Root Runner Script for Local Backend & Frontend
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ -f "$DIR/.venv/bin/python" ]; then
  PYTHON="$DIR/.venv/bin/python"
else
  PYTHON="python3"
fi

echo "=========================================================="
echo "  Starting SHE SHIELD Local Servers"
echo "  Python runtime: $($PYTHON --version)"
echo "  Backend API:    http://localhost:8080"
echo "  Web Frontend:   http://localhost:3000"
echo "=========================================================="

exec bash "$DIR/she_shield/start_all_servers.sh"
