# Hermes Agent — Persistent Docker

A fully unrestricted, persistent Docker deployment of [Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research, pre-configured with **OpenRouter** as the inference provider.

## What You Get

- **Persistent agent** — sessions, memory, skills, and config survive container restarts via Docker volumes
- **OpenRouter provider** — access 200+ models through one API key
- **No limitations** — privileged container, no resource caps, no timeouts, all tools enabled, root access
- **All tools** — terminal, file ops, web search, browser automation, vision, image gen, MCP, cron, and more
- **Gateway ready** — Telegram, Discord, Slack, WhatsApp, Email adapters pre-installed

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/weilsoun/Hermes-Master.git
cd Hermes-Master

# 2. Set your OpenRouter API key
cp .env.example .env
# Edit .env and add your key from https://openrouter.ai/keys

# 3. Build and run
docker compose up -d

# 4. Attach to the interactive CLI
docker attach hermes-agent
# (detach with Ctrl+P, Ctrl+Q)
```

## Usage

```bash
# Interactive chat
docker compose exec hermes hermes

# Single query
docker compose exec hermes hermes chat -q "What can you do?"

# Start the messaging gateway (Telegram, Discord, etc.)
docker compose exec hermes hermes gateway start

# Change model
docker compose exec hermes hermes model

# View/manage skills
docker compose exec hermes hermes skills

# Scheduled tasks
docker compose exec hermes hermes cron
```

## Configuration

All persistent config lives in the `hermes-data` Docker volume (mounted at `/opt/data`):

| File | Purpose |
|------|---------|
| `/opt/data/.env` | API keys and secrets |
| `/opt/data/config.yaml` | Model, tools, agent behavior |
| `/opt/data/SOUL.md` | Agent persona / personality |
| `/opt/data/memories/` | Persistent memory files |
| `/opt/data/skills/` | Learned and installed skills |
| `/opt/data/sessions/` | Session metadata |
| `/opt/data/state.db` | SQLite session history (FTS5) |

### Change the Model

Edit `config/config.yaml` (before first build) or `/opt/data/config.yaml` (in running container):

```yaml
model:
  default: "anthropic/claude-opus-4.6"  # or any OpenRouter model
  provider: "openrouter"
```

Or at runtime: `hermes model`

### Add Messaging Platforms

Edit `.env` and add your bot tokens, then restart:

```bash
# Example: Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-DEF
TELEGRAM_ALLOWED_USERS=your_user_id

docker compose restart
docker compose exec hermes hermes gateway start
```

## Architecture

```
Hermes-Master/
├── Dockerfile          # Full build: Debian + Python + Node + all deps
├── docker-compose.yml  # Privileged, no limits, persistent volumes
├── entrypoint.sh       # Bootstrap config on first run
├── .env.example        # Template for API keys
├── .env                # Your actual keys (gitignored)
└── config/
    ├── config.yaml     # Pre-configured for OpenRouter, all tools
    ├── .env            # Default env for first-run bootstrap
    └── SOUL.md         # Agent persona
```

## Auto-Update

Set `HERMES_AUTO_UPDATE=true` in `.env` to pull the latest Hermes code on every container restart.

## Volumes

```bash
# Inspect persistent data
docker volume inspect hermes-agent-data

# Backup
docker run --rm -v hermes-agent-data:/data -v $(pwd):/backup alpine tar czf /backup/hermes-backup.tar.gz /data

# Restore
docker run --rm -v hermes-agent-data:/data -v $(pwd):/backup alpine tar xzf /backup/hermes-backup.tar.gz -C /
```
