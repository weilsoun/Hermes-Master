#!/bin/bash
# restore.sh — spin up Hermes on a new machine from scratch
# Requirements: Docker, Docker Compose, a .env file with your API keys
# Usage: ./restore.sh

set -e
cd "$(dirname "$0")"

echo "Hermes Restore"
echo "=============="

# Check .env exists
if [ ! -f .env ]; then
  echo "ERROR: .env file missing. Copy your .env here before restoring."
  echo "  It needs at minimum: OPENROUTER_API_KEY=sk-or-..."
  exit 1
fi

# Re-clone workspace repos
echo ""
echo "Re-cloning workspace repos..."
mkdir -p data/workspace
cd data/workspace
# Detect repos from GitHub (logged in via gh)
if command -v gh &>/dev/null; then
  gh repo list weilsoun --limit 50 --json nameWithOwner -q '.[].nameWithOwner' | while read repo; do
    name=$(basename "$repo")
    if [ ! -d "$name" ]; then
      echo "  Cloning $repo..."
      gh repo clone "$repo" "$name" 2>/dev/null || true
    else
      echo "  $name already exists, skipping"
    fi
  done
else
  echo "  gh not installed yet, skipping repo clone (will work after first boot)"
fi
cd ../..

# Start container
echo ""
echo "Starting container..."
docker compose up -d --build

echo ""
echo "Done! Hermes is running."
echo "  Attach:    docker attach hermes-agent"
echo "  Detach:    Ctrl+P Ctrl+Q"
echo "  Dashboard: http://localhost:3000"
