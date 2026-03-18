# syntax=docker/dockerfile:1.6

FROM ubuntu:24.04

# ─── Build-time arguments ────────────────────────────────────────────────────
ARG DEBIAN_FRONTEND=noninteractive
ARG USER=netops
ARG UID=1000
ARG GID=1000
# Pin yq to a specific version for reproducible builds.
# To upgrade: change this value and rebuild.
ARG YQ_VERSION=v4.44.3

# ─── OCI standard labels ──────────────────────────────────────────────────────
# These labels follow the opencontainers.org specification and allow tools like
# Docker Hub, Portainer, and CI systems to display image metadata automatically.
LABEL org.opencontainers.image.title="docker_network_automation" \
      org.opencontainers.image.description="Network Automation / NetDevOps Docker image with Ansible, Nornir, Netmiko, NAPALM, Scrapli and more" \
      org.opencontainers.image.authors="Anderson Martinez Virviescas" \
      org.opencontainers.image.source="https://github.com/andersonmavi30/docker_network_automation" \
      org.opencontainers.image.licenses="MIT"

# ─── Runtime environment ─────────────────────────────────────────────────────
# PIPX_BIN_DIR  → where pipx places CLI entry-points (ansible, ansible-galaxy…)
# PIPX_HOME     → isolated virtualenvs created by pipx
# VENV_PATH     → our own project venv (separate from Ansible's pipx venv)
# PATH          → venv bin first so `python`/`pip` resolve to our venv
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PIPX_BIN_DIR=/usr/local/bin \
    PIPX_HOME=/opt/pipx \
    VENV_PATH=/opt/venv \
    PATH=/opt/venv/bin:/usr/local/bin:$PATH

# ─── System packages ─────────────────────────────────────────────────────────
# --no-install-recommends keeps the layer lean by skipping suggested extras.
# Build-time libs (build-essential, libffi-dev …) are needed to compile Python
# C-extensions (cryptography, lxml, Scrapli, etc.).
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl wget git jq \
    openssh-client \
    iputils-ping dnsutils traceroute netcat-openbsd \
    tcpdump iproute2 \
    vim nano less \
    rsync \
    python3 python3-venv python3-pip \
    pipx \
    build-essential \
    libffi-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# ─── Non-root user ───────────────────────────────────────────────────────────
# We create a dedicated 'netops' user instead of running as root.
# This is a security best practice: a compromised process inside the container
# cannot modify system files or escape via root-only syscalls.
#
# The logic below handles cases where UID/GID 1000 may already exist
# (common on some base images) to prevent build failures.
RUN set -eux; \
    # Create the group only if GID does not already exist
    if ! getent group "${GID}" >/dev/null; then \
      groupadd -g "${GID}" "${USER}"; \
    fi; \
    GROUP_NAME="$(getent group "${GID}" | cut -d: -f1)"; \
    \
    # If UID already exists rename it to our user; otherwise create it fresh
    if getent passwd "${UID}" >/dev/null; then \
      EXISTING_USER="$(getent passwd "${UID}" | cut -d: -f1)"; \
      if [ "${EXISTING_USER}" != "${USER}" ]; then \
        usermod -l "${USER}" "${EXISTING_USER}"; \
      fi; \
      usermod -g "${GROUP_NAME}" "${USER}"; \
      usermod -d "/home/${USER}" -m "${USER}" || true; \
    else \
      useradd -m -u "${UID}" -g "${GROUP_NAME}" -s /bin/bash "${USER}"; \
    fi

# ─── Ansible via pipx ────────────────────────────────────────────────────────
# pipx installs Ansible into its own isolated virtualenv under PIPX_HOME.
# This prevents Ansible's dependencies from conflicting with the project venv.
# --include-deps also exposes all Ansible sub-commands (ansible-galaxy, etc.).
RUN pipx install --include-deps ansible

# ─── Dependency files ────────────────────────────────────────────────────────
COPY collections.yml /tmp/collections.yml
COPY requirements.txt /tmp/requirements.txt

# ─── Ansible Galaxy collections ──────────────────────────────────────────────
# Collections are installed once at image build time and shared across all
# playbook runs inside the container (no network needed at runtime).
RUN ansible-galaxy collection install -r /tmp/collections.yml

# ─── Python virtual environment ──────────────────────────────────────────────
# We create a dedicated venv at /opt/venv so Python libs are isolated from
# the system Python and from Ansible's pipx venv.
# --no-cache-dir avoids storing the pip download cache inside the image layer,
# which would increase the final image size with data we never need again.
RUN python3 -m venv "${VENV_PATH}" \
    && "${VENV_PATH}/bin/pip" install --upgrade --no-cache-dir pip setuptools wheel \
    && "${VENV_PATH}/bin/pip" install --no-cache-dir -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt /tmp/collections.yml

# ─── yq (YAML processor binary) ──────────────────────────────────────────────
# yq is a standalone binary — no Python dep needed.
# We detect the CPU architecture at build time so the image can be built on
# amd64 (x86 servers), arm64 (Mac M1/M2, AWS Graviton) and armv7 (Raspberry Pi).
RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
      x86_64)  YQ_ARCH="amd64" ;; \
      aarch64) YQ_ARCH="arm64" ;; \
      armv7l)  YQ_ARCH="arm"   ;; \
      *)        echo "Unsupported arch: ${ARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" \
    && chmod +x /usr/local/bin/yq

# ─── Workspace ───────────────────────────────────────────────────────────────
# /workspace is the default mount point for host project files.
# Users mount their playbooks/scripts here with: -v "$PWD:/workspace"
WORKDIR /workspace

# Switch to the non-root user for all subsequent layers and at runtime
USER netops

CMD [ "bash" ]
