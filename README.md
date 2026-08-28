# 🚀 docker_network_automation

A **universal Network Automation / DevNet / NetDevOps Docker image** built to keep tooling **consistent, portable, and production-ready** — for both **commercial and open-source NOS**.

✅ **Python Network Automation** + ✅ **Ansible (pipx)** + ✅ **Multi-vendor Collections** + ✅ **Troubleshooting tools**

📦 **Docker Hub:** [andersonmavi30/docker_network_automation](https://hub.docker.com/r/andersonmavi30/docker_network_automation)
🦊 **GitLab mirror:** [gitlab.com/andersonmavi30/docker_network_automation](https://gitlab.com/andersonmavi30/docker_network_automation)

---

## 🎯 Project Goals

- Provide a single Docker image with common network automation tooling.
- Keep dependency isolation clean:
  - **Ansible via `pipx`**
  - **Python libraries in `/opt/venv`**
- Support multi-vendor automation workflows across **commercial vendors** (Cisco, Arista, Juniper, Aruba/HPE, Dell, Allied Telesis, Extreme, Huawei, HP/H3C) and **open-source NOS** (VyOS, Cumulus Linux, SONiC, FRRouting).

&gt; **Note:** As of v3.0.0 this image focuses on **network switching/routing**. Firewall vendors (Fortinet, Palo Alto, Check Point) were removed and will live in a dedicated image.

## 🧰 What's Inside

### 🐍 Python automation stack (`requirements.txt`)
Includes libraries for:
- HTTP/API: `requests`, `httpx`
- CLI/SSH automation: `netmiko`, `scrapli`
- Network abstraction: `napalm`
- Orchestration: `nornir`
- NETCONF: `ncclient`, `scrapli-netconf`
- gNMI (SONiC / modern telemetry): `pygnmi`
- CLI parsing: `textfsm` + `ntc-templates` (500+ multi-vendor templates)
- Source of truth: `pynetbox`
- SNMP: `pysnmp`
- Testing: `pytest`

### 🤖 Ansible (installed via `pipx`)
- Ansible is isolated from the Python venv.
- Collections are installed from `collections.yml`.

### 🏷️ Supported vendors — commercial (Ansible collections)

| Vendor | Collections | Platforms |
|---|---|---|
| **Cisco** | `cisco.ios`, `cisco.nxos`, `cisco.asa` | IOS/IOS-XE, NX-OS, ASA |
| **Arista** | `arista.eos` | EOS |
| **Juniper** | `junipernetworks.junos` | Junos |
| **Aruba / HPE** | `arubanetworks.aoscx`, `arubanetworks.aos_switch` | Aruba CX (8360, 6300, 6400...), ArubaOS-Switch / ProVision (2530, 2930, 5400R...) |
| **Dell** | `dellemc.os10`, `dellemc.os9`, `dellemc.os6` | SmartFabric OS10, legacy OS9, legacy OS6 (N-series) |
| **Allied Telesis** | `alliedtelesis.awplus` | AlliedWare Plus (x220, x330, x530, x950...) |
| **Extreme / Huawei / HP-H3C** | `community.network` | EXOS (`exos_*`), CloudEngine (`ce_*`), Comware (`comware_*`) |

### 🐧 Supported NOS — open source (Ansible collections)

| NOS | Collections | Notes |
|---|---|---|
| **VyOS** | `vyos.vyos` | Open-source router/firewall (rolling + LTS) |
| **Cumulus Linux** | `nvidia.nvue` | NVIDIA Cumulus 5.x via NVUE REST API |
| **SONiC** | `dellemc.enterprise_sonic` | Enterprise SONiC; community SONiC via gNMI (`pygnmi`) |
| **FRRouting** | `frr.frr` | Open-source routing stack (BGP, OSPF, IS-IS) — used under the hood by SONiC, Cumulus and VyOS |

Plus `community.general` for general-purpose modules.

### 🔌 Netmiko / Scrapli device types (quick reference)

For pure-Python SSH automation, use these `device_type` values:

| Vendor / NOS | Netmiko `device_type` |
|---|---|
| Cisco IOS/IOS-XE | `cisco_ios` |
| Cisco NX-OS | `cisco_nxos` |
| Cisco ASA | `cisco_asa` |
| Arista EOS | `arista_eos` |
| Juniper Junos | `juniper_junos` |
| Aruba CX / ProVision | `aruba_os` / `aruba_procurve` |
| Dell OS10 | `dell_os10` |
| Huawei | `huawei` |
| HP Comware / ProCurve | `hp_comware` / `hp_procurve` |
| Extreme EXOS | `extreme_exos` |
| Allied Telesis AW+ | `allied_telesis_awplus` |
| VyOS | `vyos` |
| Cumulus / FRR (Linux shell) | `linux` |

### 🛠️ Network & Linux utilities
Includes tools like:
`curl`, `wget`, `git`, `jq`, `ssh`, `ping`, `dig`, `traceroute`, `nc`, `tcpdump`, `iproute2`, `rsync`, `vim`, `nano`, `less`, `yq`.

## 🗂️ Repository Structure

- `Dockerfile` → image definition
- `requirements.txt` → Python dependencies
- `collections.yml` → Ansible Galaxy collections
- `.github/workflows/docker.yml` → CI/CD (build, smoke test, publish to Docker Hub)
- `README.md` → project documentation

## ⚡ Quick Start

### 1) Pull the image

```bash
docker pull andersonmavi30/docker_network_automation:3.0.0
```

### 2) Run interactive

```bash
docker run --rm -it andersonmavi30/docker_network_automation:3.0.0 bash
```

### 3) Validate tools

Inside the container:

```bash
ansible --version
ansible-galaxy collection list | head
python -c "import netmiko, napalm, nornir, scrapli, ncclient, pygnmi, textfsm; print('OK')"
yq --version
```

### 4) Mount your workspace

```bash
docker run --rm -it \
  -v "$PWD:/workspace" \
  -w /workspace \
  andersonmavi30/docker_network_automation:3.0.0 bash
```

### 5) Build locally (optional)

```bash
docker build -t andersonmavi30/docker_network_automation:3.0.0 .
```

&gt; Publishing to Docker Hub is automated: pushing a git tag `v*` triggers the GitHub Actions workflow, which builds (amd64 + arm64), smoke-tests and pushes the image with semver tags (`3.0.0`, `3.0`, `latest`).

## 🧪 Example Use Cases

### Run an Ansible command (generic example)

Requires your own inventory and credentials.

```bash
ansible -i inventories/lab.yml all -m ansible.netcommon.cli_command -a "command='show version'"
```

### Parse CLI output with Python + ntc-templates

```python
from netmiko import ConnectHandler

with ConnectHandler(device_type="aruba_os", host="10.0.0.1",
                    username="admin", password="secret") as conn:
    # use_textfsm=True parses the output with ntc-templates automatically
    interfaces = conn.send_command("show interfaces", use_textfsm=True)
    print(interfaces)
```

### Query SONiC via gNMI

```python
from pygnmi.client import gNMIclient

with gNMIclient(target=("10.0.0.2", 8080), username="admin",
                password="secret", insecure=True) as gc:
    result = gc.get(path=["openconfig-interfaces:interfaces"])
    print(result)
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

## 🔀 Workflow for changes (branch + PR/MR)

All changes go through a feature branch — never commit directly to `main`:

```bash
# Create a feature branch
git checkout -b feature/my-change

# Make edits, then verify
git status

# Commit
git add .
git commit -m "feat: describe your change"

# Push branch
git push -u github feature/my-change
```

Then open a Pull Request (GitHub) or Merge Request (GitLab) with:
- **What changed**
- **Why**
- **How it was validated**

After merging, clean up locally:

```bash
git checkout main
git pull github main
git branch -d feature/my-change
git fetch --prune
git push gitlab main   # keep the GitLab mirror in sync
```

## 🚀 Releasing a new version

```bash
git tag -a v3.0.0 -m "Release 3.0.0"
git push github v3.0.0
git push gitlab v3.0.0
```

The CI workflow builds and publishes the image to Docker Hub automatically.

## 🧬 Works Great With Labs

### PNetLab / EVE-NG
Older Docker/kernels may fail to build due to seccomp/kernel syscall limitations.

Recommended workflow:
1. Build on a modern host.
2. Push image to Docker Hub.
3. Pull/run in PNetLab/EVE-NG.

```bash
docker pull andersonmavi30/docker_network_automation:3.0.0
docker run --rm -it andersonmavi30/docker_network_automation:3.0.0 bash
```

### Containerlab
Use this image as an automation jumpbox to manage lab nodes. VyOS, FRR and SONiC VS images work great as lab targets.

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

- Add sample playbooks and inventories per vendor.
- Add more smoke tests during CI (per-vendor Ansible module checks).
- Dedicated firewall image (Fortinet, Palo Alto, Check Point).

## 📄 License

MIT License (see `LICENSE`).

## 🤝 Connect

LinkedIn: &lt;https://www.linkedin.com/in/anderson-martinez-virviescas-b5b79b106/&gt;
