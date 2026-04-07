#!/bin/bash
# save.sh — snapshot, commit, and push Hermes state to GitHub
# bind-mounted data/ is already live on disk, just commit and push.
# Usage: ./save.sh "optional message"

set -e
cd "$(dirname "$0")"

MSG="${1:-auto-save $(date '+%Y-%m-%d %H:%M')}"

# Ensure git remote has auth
TOKEN=$(grep GITHUB_TOKEN /root/.hermes/.env 2>/dev/null | cut -d= -f2 | tr -d '\n')
if [ -n "$TOKEN" ]; then
  git remote set-url origin "https://weilsoun:${TOKEN}@github.com/weilsoun/Hermes-Master.git"
fi

echo "Saving Hermes state..."
git add -A
git commit -m "save: $MSG" || echo "Nothing new to commit"
git push origin main

echo ""
echo "Saved to github.com/weilsoun/Hermes-Master"
