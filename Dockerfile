# syntax=docker/dockerfile:1.6

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=netops
ARG UID=1000
ARG GID=1000

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PIPX_BIN_DIR=/usr/local/bin \
    PIPX_HOME=/opt/pipx \
    VENV_PATH=/opt/venv \
    PATH=/opt/venv/bin:/usr/local/bin:$PATH

# Base tools + Python + build deps
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

# Ensure pipx path
RUN pipx ensurepath

# --- Create non-root user (handles existing UID/GID) ---
RUN set -eux; \
    # GID: create if missing, otherwise reuse existing group name
    if ! getent group "${GID}" >/dev/null; then \
      groupadd -g "${GID}" "${USER}"; \
    fi; \
    GROUP_NAME="$(getent group "${GID}" | cut -d: -f1)"; \
    \
    # UID: if already exists, reuse that user (rename to netops); else create netops
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

# Install Ansible via pipx (isolated from venv)
RUN pipx install --include-deps ansible

# Copy dependency files
COPY collections.yml /tmp/collections.yml
COPY requirements.txt /tmp/requirements.txt

# Install Ansible collections (system-wide for the image)
RUN ansible-galaxy collection install -r /tmp/collections.yml

# Create venv and install Python libs
RUN python3 -m venv "${VENV_PATH}" \
    && "${VENV_PATH}/bin/pip" install --upgrade pip setuptools wheel \
    && "${VENV_PATH}/bin/pip" install -r /tmp/requirements.txt

# Install yq (binary)
RUN curl -L -o /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# Workspace
WORKDIR /workspace

# Use non-root by default
USER netops

CMD [ "bash" ]

