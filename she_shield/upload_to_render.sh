#!/bin/bash
# SHE SHIELD - Upload & Seed PostgreSQL Database to Render Cloud
# Usage: ./upload_to_render.sh "<RENDER_EXTERNAL_DATABASE_URL>"

if [ -z "$1" ]; then
  echo "Usage: ./upload_to_render.sh \"postgresql://username:password@dpg-xxx.render.com/dbname\""
  exit 1
fi

RENDER_URL="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/seed_she_shield.sql"

if [ ! -f "$SQL_FILE" ]; then
  echo "Error: seed_she_shield.sql not found at $SQL_FILE"
  exit 1
fi

echo "=========================================================="
echo "  SHE SHIELD - Uploading Schema & Real Data to Render..."
echo "=========================================================="
echo "Target Cloud: Render PostgreSQL"

/opt/homebrew/bin/psql "$RENDER_URL" -f "$SQL_FILE"

if [ $? -eq 0 ]; then
  echo ""
  echo "SUCCESS: PostgreSQL schema and all 5 tables successfully seeded on Render!"
  echo "Tables populated: users, sos_cases, cyber_complaints, vault_assets, guardians."
else
  echo ""
  echo "Error connecting or uploading to Render. Please verify your Render Database URL."
fi
