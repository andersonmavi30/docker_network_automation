# 🚀 docker_network_automation

A **Network Automation / DevNet / NetDevOps Docker image** built to keep tooling **consistent, portable, and production-ready**.

✅ **Python Network Automation** + ✅ **Ansible (pipx)** + ✅ **Multi-vendor Collections** + ✅ **Troubleshooting tools**

---

## 🎯 Project Goals

- Provide a single Docker image with common network automation tooling.
- Keep dependency isolation clean:
  - **Ansible via `pipx`**
  - **Python libraries in `/opt/venv`**
- Support multi-vendor automation workflows (Cisco, Arista, Juniper, Aruba/HPE, Dell, Allied Telesis, Extreme, Huawei, HP/H3C, etc.).

## 🧰 What’s Inside

### 🐍 Python automation stack (`requirements.txt`)
Includes libraries for:
- HTTP/API: `requests`, `httpx`
- CLI/SSH automation: `netmiko`, `scrapli`
- Network abstraction: `napalm`
- Orchestration: `nornir`
- NETCONF: `ncclient`
- Source of truth: `pynetbox`
- SNMP: `pysnmp`
- Testing: `pytest`

### 🤖 Ansible (installed via `pipx`)
- Ansible is isolated from the Python venv.
- Collections are installed from `collections.yml`.

### 🏷️ Supported vendors (Ansible collections)

The image ships pinned collections focused on **network switching/routing vendors**:

| Vendor | Collections | Platforms |
|---|---|---|
| **Cisco** | `cisco.ios`, `cisco.nxos`, `cisco.asa` | IOS/IOS-XE, NX-OS, ASA |
| **Arista** | `arista.eos` | EOS |
| **Juniper** | `junipernetworks.junos` | Junos |
| **Aruba / HPE** | `arubanetworks.aoscx`, `arubanetworks.aos_switch` | Aruba CX (8360, 6300, 6400...), ArubaOS-Switch / ProVision (2530, 2930, 5400R...) |
| **Dell** | `dellemc.os10`, `dellemc.os9`, `dellemc.os6` | SmartFabric OS10, legacy OS9, legacy OS6 (N-series) |
| **Allied Telesis** | `alliedtelesis.awplus` | AlliedWare Plus (x220, x330, x530, x950...) |
| **Extreme / Huawei / HP-H3C** | `community.network` | EXOS (`exos_*`), CloudEngine (`ce_*`), Comware (`comware_*`) |

Plus `community.general` for general-purpose modules.

### 🛠️ Network & Linux utilities
Includes tools like:
`curl`, `wget`, `git`, `jq`, `ssh`, `ping`, `dig`, `traceroute`, `nc`, `tcpdump`, `iproute2`, `rsync`, `vim`, `nano`, `less`, `yq`.

## 🗂️ Repository Structure

- `Dockerfile` → image definition
- `requirements.txt` → Python dependencies
- `collections.yml` → Ansible Galaxy collections
- `README.md` → project documentation

## ⚡ Quick Start

### 1) Build the image

```bash
docker build -t andersonmavi30/docker_network_automation:2.0.0 .
```

### 2) Run interactive

```bash
docker run --rm -it andersonmavi30/docker_network_automation:2.0.0 bash
```

### 3) Validate tools

Inside the container:

```bash
ansible --version
ansible-galaxy collection list | head
python -c "import netmiko, napalm, nornir, scrapli, ncclient; print('OK')"
yq --version
```

### 4) Mount your workspace

```bash
docker run --rm -it \
  -v "$PWD:/workspace" \
  -w /workspace \
  andersonmavi30/docker_network_automation:2.0.0 bash
```

### 5) Publish to Docker Hub

```bash
docker login
docker push andersonmavi30/docker_network_automation:2.0.0

# Optional: tag as latest
docker tag andersonmavi30/docker_network_automation:2.0.0 andersonmavi30/docker_network_automation:latest
docker push andersonmavi30/docker_network_automation:latest
```

## 🧪 Example Use Cases

### Run an Ansible command (generic example)

Requires your own inventory and credentials.

```bash
ansible -i inventories/lab.yml all -m ansible.netcommon.cli_command -a "command='show version'"
```

### Typical `/workspace` layout

```text
inventories/
playbooks/
group_vars/
host_vars/
scripts/
templates/
```

## 🔀 Workflow for changes (branch + PR)

If you want to implement changes safely:

```bash
# Create a feature branch
git checkout -b feature/my-change

# Make edits, then verify
git status

# Commit
git add .
git commit -m "feat: describe your change"

# Push branch
git push -u origin feature/my-change
```

Then open a Pull Request with:
- **What changed**
- **Why**
- **How it was validated**

## 🧬 Works Great With Labs

### PNetLab / EVE-NG
Older Docker/kernels may fail to build due to seccomp/kernel syscall limitations.

Recommended workflow:
1. Build on a modern host.
2. Push image to Docker Hub.
3. Pull/run in PNetLab/EVE-NG.

```bash
docker pull andersonmavi30/docker_network_automation:2.0.0
docker run --rm -it andersonmavi30/docker_network_automation:2.0.0 bash
```

### Containerlab
Use this image as an automation jumpbox to manage lab nodes.

## 🔧 Customization

- Add Python libraries: edit `requirements.txt` and rebuild.
- Add Ansible collections: edit `collections.yml` and rebuild.

## 🧯 Troubleshooting

### `No space left on device` during build

```bash
docker system df
docker builder prune
```

### UID/GID conflicts
The Dockerfile already handles pre-existing UID/GID values to prevent build failures.

## 🔒 Security & Best Practices

- Runs as non-root user (`netops`) by default.
- Ansible installed via `pipx`.
- Python libs installed in `/opt/venv`.

## 🗺️ Roadmap

- Add sample playbooks and inventories.
- Add GitHub Actions for automatic build/push.
- Add smoke tests during CI.
- Add semantic tags (`v2.0.0`, `latest`).

## 📄 License

MIT License (see `LICENSE`).

## 🤝 Connect

LinkedIn: <https://www.linkedin.com/in/anderson-martinez-virviescas-b5b79b106/>
