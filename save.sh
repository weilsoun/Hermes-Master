#!/bin/bash
# save.sh — snapshot and commit the entire Hermes agent state to git
# Since ./data/ is bind-mounted, it's already live on disk.
# This just commits whatever is there.
#
# Usage: ./save.sh "optional message"
# Run from weiltron-1 in ~/Hermes-Master/

set -e
cd "$(dirname "$0")"

MSG="${1:-auto-save $(date '+%Y-%m-%d %H:%M')}"

echo "Saving Hermes state..."
git add data/ projects/
git add -u
git commit -m "save: $MSG" || echo "Nothing new to commit"
git push origin main

echo ""
echo "Done. Restore on any machine with:"
echo "  git clone https://github.com/weilsoun/Hermes-Master"
echo "  cd Hermes-Master && cp .env.example .env  # add your API keys"
echo "  docker compose up -d --build"
