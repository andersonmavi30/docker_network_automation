# 🚀 docker_network_automation

A **professional Network Automation / DevNet / NetDevOps Docker image** built to keep your tooling **consistent, portable, and production-ready** across labs and real environments.

✅ **Python Network Automation** + ✅ **Ansible (pipx)** + ✅ **Multi-vendor Collections** + ✅ **Network troubleshooting tools**

> Perfect for **DevNet labs**, **NetDevOps pipelines**, **Containerlab/PNetLab/EVE-NG**, and daily automation work.

---

## 🎯 Project Goals

- Provide a **single Docker image** with the most common Network Automation tooling
- Keep dependencies clean:
  - **Ansible installed via `pipx`** (isolated)
  - **Python libs inside a dedicated venv** (`/opt/venv`)
- Support a **multi-vendor automation workflow** (Cisco, Fortinet, Palo Alto, Check Point, Juniper, Arista, etc.)

---

## 🧰 What’s Inside

### 🐍 Python Automation Stack (`requirements.txt`)
Includes key libraries such as:
- 🌐 HTTP/API: `requests`, `httpx`
- 🧑‍💻 CLI/SSH automation: `netmiko`, `scrapli`
- 🧩 Network abstraction: `napalm`
- 🧠 Orchestration: `nornir`
- 🔐 NETCONF: `ncclient`
- 🗃️ Source of truth: `pynetbox`
- 📡 SNMP: `pysnmp`
- ✅ Testing: `pytest`

### 🤖 Ansible (installed via `pipx`)
- ✅ Ansible isolated from Python venv to avoid dependency conflicts
- 📦 Collections installed from `collections.yml`

### 🛠️ Network & Linux Utilities
- `curl`, `wget`, `git`, `jq`, `ssh`
- `ping`, `dig`, `traceroute`, `nc`
- `tcpdump`, `iproute2`, `rsync`, `vim`, `nano`, `less`
- `yq` (binary)

---

## 🗂️ Repository Structure

- 📄 `Dockerfile` → image definition
- 📄 `requirements.txt` → Python dependencies (installed into `/opt/venv`)
- 📄 `collections.yml` → Ansible Galaxy collections
- 📄 `README.md` → project documentation

---

## ⚡ Quick Start

### 🧱 Build the image
```bash
docker build -t andersonmavi30/docker_network_automation:2.0.0 .
▶️ Run interactive
docker run --rm -it andersonmavi30/docker_network_automation:2.0.0 bash
✅ Validate tools
Inside the container:

ansible --version
ansible-galaxy collection list | head

python -c "import netmiko, napalm, nornir, scrapli, ncclient; print('OK')"
yq --version
📁 Recommended: Mount Your Workspace
Work directly from your local repo/files as /workspace:

docker run --rm -it \
  -v "$PWD:/workspace" \
  -w /workspace \
  andersonmavi30/docker_network_automation:2.0.0 bash
📦 Publish to Docker Hub
docker login
docker push andersonmavi30/docker_network_automation:2.0.0
🏷️ Optional: tag as latest
docker tag andersonmavi30/docker_network_automation:2.0.0 andersonmavi30/docker_network_automation:latest
docker push andersonmavi30/docker_network_automation:latest
🧪 Example Use Cases
🤖 Run an Ansible command (generic example)
Requires your own inventory and credentials per vendor.

ansible -i inventories/lab.yml all -m ansible.netcommon.cli_command -a "command='show version'"
🧠 Typical /workspace layout
inventories/

playbooks/

group_vars/

host_vars/

scripts/ (Python automation)

templates/

🧬 Works Great With Labs
🧪 PNetLab / EVE-NG
Older Docker/kernels may fail to build due to seccomp/kernel syscall limitations.
✅ Recommended workflow:

Build on a modern host

Push to Docker Hub

Pull and run inside PNetLab/EVE-NG

docker pull andersonmavi30/docker_network_automation:2.0.0
docker run --rm -it andersonmavi30/docker_network_automation:2.0.0 bash
🧱 Containerlab
Use this image as your automation “jumpbox” container to manage the lab nodes.

🔧 Customization
➕ Add more Python libraries
Edit requirements.txt and rebuild.

➕ Add more Ansible collections
Edit collections.yml and rebuild.

🧯 Troubleshooting
❌ No space left on device during build
Your host ran out of disk space in Docker storage.
Check usage:

docker system df
Clean build cache (careful in shared systems):

docker builder prune
👤 UID/GID conflicts
The Dockerfile is designed to handle existing UID/GID so the build doesn’t fail.

🔒 Security & Best Practices
👤 Runs as non-root user by default (netops)

🧪 Ansible installed via pipx (isolated environment)

🐍 Python libs installed into a dedicated venv: /opt/venv

🗺️ Roadmap
✅ Add sample playbooks & inventories

✅ Add GitHub Actions for automatic build + push to Docker Hub

✅ Add smoke tests (imports, versions) during CI

✅ Add semantic tags (v2.0.0, latest)

📄 License
MIT License (see LICENSE).

🤝 Connect
🔗 LinkedIn: https://www.linkedin.com/in/anderson-martinez-virviescas-b5b79b106/

