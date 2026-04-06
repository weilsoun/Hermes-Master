# Hermes Agent - Persistent, Unrestricted Docker Image
# Provider: OpenRouter | No resource limitations | Full toolset
FROM debian:bookworm

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# ─────────────────────────────────────────────────────────────────────────────
# System packages — install EVERYTHING the agent could ever need
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential gcc g++ make cmake pkg-config \
    python3 python3-pip python3-dev python3-venv \
    nodejs npm \
    # System tools
    curl wget git git-lfs openssh-client rsync unzip zip \
    ripgrep fd-find jq yq tree htop ncdu tmux \
    # Networking
    net-tools iproute2 iputils-ping dnsutils nmap socat netcat-openbsd \
    # Media / vision
    ffmpeg imagemagick libmagic1 \
    # Libraries for Python packages
    libffi-dev libssl-dev libxml2-dev libxslt1-dev \
    zlib1g-dev libjpeg-dev libpng-dev libwebp-dev \
    libsqlite3-dev libpq-dev \
    # Browsers & rendering
    chromium chromium-driver \
    # Docker CLI (for Docker-in-Docker if needed)
    docker.io \
    # Misc utilities
    sudo cron at procps lsof strace file less vim nano \
    ca-certificates gnupg2 locales tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# ─────────────────────────────────────────────────────────────────────────────
# Clone and install Hermes Agent with ALL extras
# ─────────────────────────────────────────────────────────────────────────────
RUN git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes

WORKDIR /opt/hermes

# Install Python deps (break system packages — this IS the system)
RUN pip install --no-cache-dir --break-system-packages -e ".[all]"

# Install Node deps + Playwright with full Chromium
RUN npm install --prefer-offline --no-audit && \
    npx playwright install --with-deps chromium && \
    cd /opt/hermes/scripts/whatsapp-bridge 2>/dev/null && npm install --prefer-offline --no-audit || true && \
    npm cache clean --force

# ─────────────────────────────────────────────────────────────────────────────
# Persistent data volume
# ─────────────────────────────────────────────────────────────────────────────
ENV HERMES_HOME=/opt/data
RUN mkdir -p /opt/data

# Copy our custom entrypoint and configs
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

COPY config/ /opt/defaults/

# ─────────────────────────────────────────────────────────────────────────────
# Runtime configuration — NO LIMITS
# ─────────────────────────────────────────────────────────────────────────────
# Run as root — no permission restrictions
USER root

# No ulimits, no seccomp, no apparmor constraints enforced from inside
# (container-level limits are removed via docker-compose privileged mode)

# Unlimited command timeout
ENV TERMINAL_TIMEOUT=0

# Keep terminal environments alive indefinitely
ENV TERMINAL_LIFETIME_SECONDS=0

VOLUME ["/opt/data"]

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["hermes"]
