#!/bin/bash
# save.sh — commit and push all Hermes state to GitHub
# gh auth is pre-configured via entrypoint, no credentials needed.
# Usage: ./save.sh "optional message"

set -e
cd "$(dirname "$0")"

MSG="${1:-auto-save $(date '+%Y-%m-%d %H:%M')}"

git add -A
git commit -m "save: $MSG" || echo "Nothing new to commit"
git push origin main

echo "Saved to github.com/weilsoun/Hermes-Master"
