#!/bin/bash
# Hermes Agent Docker Entrypoint
# Bootstraps persistent config into the data volume, then runs hermes.
set -e

HERMES_HOME="/opt/data"
DEFAULTS_DIR="/opt/defaults"
INSTALL_DIR="/opt/hermes"

# ── Create directory structure ──────────────────────────────────────────────
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,cache}

# ── Bootstrap config files (only on first run) ─────────────────────────────
if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$DEFAULTS_DIR/.env" "$HERMES_HOME/.env"
    echo "[hermes] Created .env from defaults"
fi

if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    cp "$DEFAULTS_DIR/config.yaml" "$HERMES_HOME/config.yaml"
    echo "[hermes] Created config.yaml from defaults"
fi

if [ ! -f "$HERMES_HOME/SOUL.md" ]; then
    cp "$DEFAULTS_DIR/SOUL.md" "$HERMES_HOME/SOUL.md"
    echo "[hermes] Created SOUL.md from defaults"
fi

# ── Sync bundled skills (preserves user edits) ─────────────────────────────
if [ -d "$INSTALL_DIR/skills" ] && [ -f "$INSTALL_DIR/tools/skills_sync.py" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" 2>/dev/null || true
fi

# ── Pull latest hermes on startup (optional, controlled by env) ────────────
if [ "${HERMES_AUTO_UPDATE:-false}" = "true" ]; then
    echo "[hermes] Pulling latest updates..."
    cd "$INSTALL_DIR" && git pull --ff-only 2>/dev/null && \
        pip install --no-cache-dir --break-system-packages -e ".[all]" -q 2>/dev/null || true
    cd /
fi

echo "[hermes] Ready. HERMES_HOME=$HERMES_HOME"
echo "[hermes] Provider: OpenRouter"
echo "[hermes] Starting: $@"

exec "$@"
