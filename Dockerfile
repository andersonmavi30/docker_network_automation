# syntax=docker/dockerfile:1.6
FROM ubuntu:24.04

# Prevent apt from prompting questions during build
ARG DEBIAN_FRONTEND=noninteractive

# Create a non-root user (helps when mounting volumes and avoids running everything as root)
ARG USER=netops
ARG UID=1000
ARG GID=1000

# ---- Base packages: downloads, git, JSON tools, SSH client, network troubleshooting, editors, Python, and build deps ----
# --no-install-recommends keeps the image smaller by skipping extra suggested packages
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

# ---- pipx: install Python CLI tools in isolated environments (ideal for Ansible) ----
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx ensurepath

# ---- Create the non-root user inside the container ----
RUN groupadd -g ${GID} ${USER} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# ---- Install Ansible (isolated via pipx) ----
RUN pipx install "ansible-core==2.17.*" \
 && pipx inject ansible-core argcomplete passlib paramiko jmespath

# ---- Install Ansible Galaxy collections from a file (clean & maintainable) ----
COPY collections.yml /tmp/collections.yml
RUN ansible-galaxy collection install -r /tmp/collections.yml \
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

# ---- Default workspace directory (mount your repo here) ----
WORKDIR /workspace
RUN chown -R ${USER}:${USER} /workspace

# Run as non-root by default
USER ${USER}

# Quality-of-life defaults
ENV PYTHONUNBUFFERED=1
ENV ANSIBLE_HOST_KEY_CHECKING=False

# Start an interactive shell by default
CMD ["/bin/bash"]

