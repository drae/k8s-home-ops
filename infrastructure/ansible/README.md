# Non-kubernetes Infrastructure

This directory contains the consolidated Ansible configuration for setting up "non-kubernetes" elements of my home ops systems. These are apollo - my NAS, and gravity - my tvheadend server. A minimal OS configuration is used, Docker is used for managing additional software components.

## Prerequisites

- Python 3.x
- [Task](https://taskfile.dev/) runner installed
- Access to target machines via SSH

✳️ Note: the OS used is assumed to be Debian based. Specifically, I use Ubuntu for apollo and RaspberryPi OS for gravity.

## Setup

### 1. Initialize Python Virtual Environment

Before running any Ansible playbooks, you need to set up the Python virtual environment with all required dependencies:

```bash
task ansible:venv
```

This command will:

- Create a Python virtual environment in `.venv/`
- Install all Python packages from `requirements.txt`
- Install all Ansible collections and roles from `requirements.yml`

### 2. Dependencies

The setup installs the following key components:

#### Python Packages

- `ansible` - Core Ansible automation platform
- `ansible-lint` - Linting tool for Ansible playbooks
- `bcrypt` - Password hashing library
- `jmespath` - JSON query language
- `netaddr` - Network address manipulation
- `openshift` - OpenShift/Kubernetes client library
- `passlib` - Password hashing and verification

#### Ansible Collections

- `ansible.posix` - POSIX-specific modules
- `ansible.utils` - Utility modules for data manipulation
- `community.general` - General community modules
- `community.sops` - SOPS encryption/decryption modules
- `community.docker` - Docker management modules

#### Ansible Roles

- `geerlingguy.pip` - Python pip management
- `mrlesmithjr.zfs` - ZFS filesystem management
- `geerlingguy.docker` - Docker installation and configuration

## Usage

### Running Playbooks

Use the `task ansible:run` command to execute playbooks against your clusters:

```bash
task ansible:run machine=<machine> playbook=<playbook>
```

#### Available Machines

- `nas` - NAS services (runs on apollo host)
- `tvh` - TVHeadend services (runs on gravity host)

#### Available Playbooks

- `os` - Operating system configuration
- `apps` - Application deployment and configuration

### Examples

```bash
# Configure the operating system for NAS services
task ansible:run machine=nas playbook=os

# Deploy applications to TVH services
task ansible:run machine=tvh playbook=docker

# Run with additional Ansible arguments (dry-run with diff)
task ansible:run machine=nas playbook=apps -- --check --diff
```

### Direct Ansible Playbook Usage

You can also run the consolidated playbooks directly with ansible-playbook:

```bash
# Run only NAS (storage) setup
ansible-playbook -i inventory/hosts.yml playbooks/nas/os.yml playbooks/nas/apps.yml

# Run only TVH (TVHeadend) setup  
ansible-playbook -i inventory/hosts.yml playbooks/tvh/os.yml playbooks/tvh/apps.yml

# Run only OS setup (no applications)
ansible-playbook -i inventory/hosts.yml playbooks/common/os-base.yml playbooks/nas/os.yml playbooks/tvh/os.yml
```

### Environment Variables

The following environment variables are automatically set when running tasks:

- `PATH` - Includes the virtual environment's bin directory
- `VIRTUAL_ENV` - Points to the project's virtual environment
- `ANSIBLE_CONFIG` - Points to the project's ansible.cfg file
- `ANSIBLE_COLLECTIONS_PATH` - Path to installed Ansible collections
- `ANSIBLE_ROLES_PATH` - Path to installed Ansible roles (includes custom roles)
- `ANSIBLE_VARS_ENABLED` - Enables host_group_vars for variable loading

## Configuration & Variables

### Ansible Configuration

The `ansible.cfg` file provides centralized configuration:

- **Inventory path**: Points to `infrastructure/ansible/inventory/hosts.yml`
- **Roles path**: Includes both local roles and galaxy-installed roles
- **SOPS integration**: Enables `community.sops.sops` vars plugin for automatic secret decryption
- **Modern callbacks**: Uses `ansible.builtin.default` with YAML output format
- **SSH optimization**: Includes connection reuse and performance settings

### Variable Organization

- **`group_vars/all.yml`**: Variables shared by both systems (Docker config, base packages, SSH keys, timezone, file paths)
- **`host_vars/apollo.sops.yaml`**: SOPS-encrypted secrets for apollo host (VPN keys, passwords, etc.)

### Path Resolution

File and template paths are configured to work from different contexts:

- **Playbook files**: `ansible_files_dir: ../../files` (relative to playbook directory)
- **Absolute paths**: Ansible configuration uses absolute paths from project root

## Consolidated Structure Benefits

## Safety Features

- **Dry Run Support**: Use `-- --check` to perform dry runs without making changes

## Troubleshooting

### Common Issues

1. **Virtual Environment Not Found**

   ```bash
   task ansible:venv
   ```

2. **Inventory File Missing**
   - Ensure the inventory file exists at `<machine>/inventory/hosts.yml`

3. **Playbook Not Found**
   - Verify the playbook exists at `<machine>/playbooks/<playbook>.yml`

### Debugging

- Use `-- --check --diff` to see what changes would be made
- Add `-- -vv` for verbose output
- Use `-- --limit <host>` to target specific hosts
