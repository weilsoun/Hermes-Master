#!/bin/bash
# save.sh — commit current Hermes state to git
# Run this on weiltron-1 whenever you want to snapshot your AI system.
# Usage: ./save.sh "optional message"

set -e
cd "$(dirname "$0")"

MSG="${1:-auto-save $(date '+%Y-%m-%d %H:%M')}"

# Copy live data from container into ./data/
echo "Syncing from container..."
CONTAINER=$(docker ps -qf "name=hermes-agent")

if [ -z "$CONTAINER" ]; then
  echo "ERROR: hermes-agent container not running"
  exit 1
fi

mkdir -p data/opt-data data/hermes data/config

docker cp "$CONTAINER":/opt/data/. data/opt-data/ 2>/dev/null
docker cp "$CONTAINER":/root/.hermes/. data/hermes/ 2>/dev/null
docker cp "$CONTAINER":/root/.config/. data/config/ 2>/dev/null

# Commit
echo "Committing..."
git add data/
git add -u
git commit -m "save: $MSG" || echo "Nothing new to commit"
git push origin main

echo ""
echo "Saved! Run 'git pull' on any machine to get this state."

# Save project definitions (already in git, just make sure they're current)
echo "Project definitions are in projects/ folder (already tracked by git)"
