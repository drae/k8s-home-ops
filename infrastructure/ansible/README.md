# Non-kubernetes Infrastructure

This directory contains the consolidated Ansible configuration for setting up "non-kubernetes" elements of my home ops systems. These are apollo - my NAS, and gravity - my tvheadend server. A minimal OS configuration is used, Docker is used for managing additional software components.

## Directory Structure

```text
infrastructure/ansible/
├── README.md                 # This file
├── requirements.txt          # Python dependencies
├── requirements.yml          # Ansible collections and roles
├── inventory/
│   ├── hosts.yml            # Combined inventory for both apollo and gravity
│   ├── group_vars/
│   │   └── all.yml         # Common variables (Docker config, base packages, etc.)
│   └── host_vars/
│       ├── apollo.yml      # Apollo-specific variables (ZFS packages, etc.)
│       └── gravity.yml     # Gravity-specific variables (minimal)
├── playbooks/
│   ├── site.yml            # Master orchestrator playbook
│   ├── common/
│   │   ├── os-base.yml     # Shared OS setup (packages, users, networking)
│   │   └── docker-base.yml # Shared Docker setup and node-exporter
│   ├── apollo/
│   │   ├── os.yml         # Apollo-specific OS (ZFS, storage configs)
│   │   └── apps.yml       # Apollo-specific applications (downloads)
│   └── gravity/
│       ├── os.yml         # Gravity-specific OS (sysctl, rootless containers)
│       └── apps.yml       # Gravity TVHeadend application
├── files/                  # Static configuration files and docker-compose YAML
│   ├── docker-compose/     # Static docker-compose files (no templating)
│   │   ├── tvh/
│   │   ├── node-exporter/
│   │   ├── sabnzbd/
│   │   └── ...
│   └── ...                 # Other static files
└── templates/              # Jinja2 templates with {{ }} variables
    ├── docker-compose@.service.j2
    ├── zfs-exporter.service.j2
    └── ...
```

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

- `apollo` - NAS
- `gravity` - TVHeadend

#### Available Playbooks

- `os` - Operating system configuration
- `apps` - Application deployment and configuration

### Examples

```bash
# Configure the operating system on apollo
task ansible:run machine=apollo playbook=os

# Deploy applications to gravity
task ansible:run machine=gravity playbook=apps

# Run with additional Ansible arguments
task ansible:run machine=apollo playbook=os -- --check --diff
```

### Direct Ansible Playbook Usage

You can also run the consolidated playbooks directly with ansible-playbook:

```bash
# Run everything for both systems
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Run only Apollo (storage) setup
ansible-playbook -i inventory/hosts.yml playbooks/apollo/os.yml playbooks/apollo/apps.yml

# Run only Gravity (TVHeadend) setup
ansible-playbook -i inventory/hosts.yml playbooks/gravity/os.yml playbooks/gravity/apps.yml

# Run only common setup for all hosts
ansible-playbook -i inventory/hosts.yml playbooks/common/os-base.yml playbooks/common/docker-base.yml

# Run only OS setup (no applications)
ansible-playbook -i inventory/hosts.yml playbooks/common/os-base.yml playbooks/apollo/os.yml playbooks/gravity/os.yml
```

### Environment Variables

The following environment variables are automatically set when running tasks:

- `PATH` - Includes the virtual environment's bin directory
- `VIRTUAL_ENV` - Points to the project's virtual environment
- `ANSIBLE_COLLECTIONS_PATH` - Path to installed Ansible collections
- `ANSIBLE_ROLES_PATH` - Path to installed Ansible roles
- `ANSIBLE_VARS_ENABLED` - Enables host_group_vars for variable loading

## Variable Organization

- **`group_vars/all.yml`**: Variables shared by both systems (Docker config, base packages, SSH keys, timezone)
- **`host_vars/apollo.yml`**: Apollo-specific variables (additional ZFS/storage packages)
- **`host_vars/gravity.yml`**: Gravity-specific variables (minimal - just empty additional package lists)

The variable structure uses a base + additional pattern:

- `os_packages_install_base` (common packages) + `os_packages_install_additional` (system-specific)
- Final merged list: `os_packages_install: "{{ os_packages_install_base + os_packages_install_additional }}"`

## Consolidated Structure Benefits

1. **DRY (Don't Repeat Yourself)**: Common tasks defined once, no duplication
2. **Clear Separation**: System-specific needs are clearly isolated
3. **Maintainable**: Easy to see what's shared vs system-specific
4. **Flexible Execution**: Run specific parts or everything
5. **Scalable**: Easy to add new systems following the same pattern

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

