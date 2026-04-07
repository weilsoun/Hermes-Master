#!/bin/bash
# save.sh — snapshot, commit, and push Hermes state to GitHub

set -e
cd "$(dirname "$0")"

MSG="${1:-auto-save $(date '+%Y-%m-%d %H:%M')}"

# Get token from gh CLI
TOKEN=$(gh auth token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "ERROR: gh not authenticated. Run: gh auth login"
  exit 1
fi

git remote set-url origin "https://weilsoun:${TOKEN}@github.com/weilsoun/Hermes-Master.git"

echo "Saving Hermes state..."
git add -A
git commit -m "save: $MSG" || echo "Nothing new to commit"
git push origin main

echo ""
echo "Saved to github.com/weilsoun/Hermes-Master"
