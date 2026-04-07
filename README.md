# Hermes Agent — Factor1Digital Docker Setup

Persistent Hermes AI Agent. All data lives in ./data/ next to this file.

## Directory Structure

Hermes-Master/
  docker-compose.yml    <- container config
  Dockerfile            <- image build
  entrypoint.sh         <- startup script
  .env                  <- your API keys (never commit)
  migrate-volumes.sh    <- one-time migration from old named volumes
  data/                 <- ALL persistent data (bind-mounted)
    opt-data/           <- Hermes brain: memory, skills, sessions, config
    hermes/             <- company KB, task log (~/.hermes)
    config/             <- GitHub CLI auth (~/.config)
    workspace/          <- all Git repos (/workspace)

## Daily Usage

  docker compose up -d            # start
  docker attach hermes-agent      # attach (talk to Hermes)
  Ctrl+P then Ctrl+Q              # detach WITHOUT stopping
  docker compose down             # stop
  docker compose restart          # restart, data is safe

## First Time Migration (from old named volumes)

  chmod +x migrate-volumes.sh
  ./migrate-volumes.sh a9cd71e9a251
  docker stop hermes-agent
  docker compose up -d --build

## Ports

  3000 = ARIA Dashboard (http://localhost:3000)

## Backup

  cp -r ./data ./data-backup-$(date +%Y%m%d)

## Updating Hermes

  docker compose down
  docker compose up -d --build
