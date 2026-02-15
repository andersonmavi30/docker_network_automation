# syntax=docker/dockerfile:1.6
FROM ubuntu:24.04

# Avoid interactive prompts during apt installs
ARG DEBIAN_FRONTEND=noninteractive

# Create a non-root user (helps with file permissions when mounting volumes)
ARG USER=netops
ARG UID=1000
ARG GID=1000

# ---- Base packages: tooling for downloads, git, JSON parsing, SSH, networking, debugging, and Python ----
# --no-install-recommends keeps the image smaller by skipping "recommended" extras
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git unzip zip jq \
    openssh-client \
    iputils-ping dnsutils traceroute netcat-openbsd \
    tcpdump iproute2 \
    vim nano less \
    rsync \
    python3 python3-venv python3-pip pipx \
    build-essential gcc g++ make \
    libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# ---- pipx: install Python CLI tools in isolated environments (great for Ansible, etc.) ----
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx ensurepath

# ---- Create the non-root user inside the container ----
RUN groupadd -g ${GID} ${USER} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# ---- Install Ansible (isolated with pipx) + common network vendor collections ----
# This avoids mixing Ansible dependencies with your main Python venv
RUN pipx install "ansible-core==2.17.*" \
 && pipx inject ansible-core argcomplete passlib paramiko jmespath \
 && ansible-galaxy collection install \
    cisco.ios cisco.nxos cisco.asa arista.eos junipernetworks.junos \
    fortinet.fortios paloaltonetworks.panos check_point.mgmt \
    community.general community.network \
 && rm -rf /root/.ansible

# ---- Python virtual environment for your automation libraries (requirements.txt) ----
ENV VENV_PATH=/opt/venv
RUN python3 -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Copy Python dependencies and install them into the venv
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -U pip wheel setuptools \
 && pip install --no-cache-dir -r /tmp/requirements.txt

# ---- Optional: yq binary for quick YAML processing in scripts/pipelines ----
RUN curl -fsSL -o /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
 && chmod +x /usr/local/bin/yq

# ---- Default working directory (mount your repo here) ----
WORKDIR /workspace
RUN chown -R ${USER}:${USER} /workspace

# Switch to the non-root user for day-to-day work
USER ${USER}

# Quality-of-life defaults
ENV PYTHONUNBUFFERED=1
ENV ANSIBLE_HOST_KEY_CHECKING=False

# Start an interactive shell by default
CMD ["/bin/bash"]

