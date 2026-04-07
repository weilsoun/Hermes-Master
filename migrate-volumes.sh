#!/bin/bash
CONTAINER_ID="${1:-a9cd71e9a251}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"

echo "Hermes Volume Migration -> $DATA_DIR"
docker inspect "$CONTAINER_ID" > /dev/null 2>&1 || { echo "ERROR: Container not found"; exit 1; }

mkdir -p "$DATA_DIR/opt-data" "$DATA_DIR/hermes" "$DATA_DIR/config" "$DATA_DIR/workspace"

echo "[1/4] /opt/data..."
docker cp "$CONTAINER_ID":/opt/data/. "$DATA_DIR/opt-data/"

echo "[2/4] /root/.hermes..."
docker cp "$CONTAINER_ID":/root/.hermes/. "$DATA_DIR/hermes/"

echo "[3/4] /root/.config..."
docker cp "$CONTAINER_ID":/root/.config/. "$DATA_DIR/config/"
docker cp "$CONTAINER_ID":/root/.gitconfig "$DATA_DIR/" 2>/dev/null || true
docker cp "$CONTAINER_ID":/root/.git-credentials "$DATA_DIR/" 2>/dev/null || true

echo "[4/4] /workspace..."
docker cp "$CONTAINER_ID":/workspace/. "$DATA_DIR/workspace/"

echo ""
echo "Done! Total: $(du -sh "$DATA_DIR" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. docker stop hermes-agent"
echo "  2. docker compose up -d --build"
echo "  3. open http://localhost:3000"
