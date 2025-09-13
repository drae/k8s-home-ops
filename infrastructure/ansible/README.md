# Non-kubernetes Infrastructure

This directory contains the Ansible configuration for setting up "non-kubernetes" elements of my home ops systems. These are apollo - my NAS, and gravity - my tvheadend server. A minimal OS configuration is used, Docker is used for managing additional software components.

## Directory Structure

```text
infrastructure/ansible/
├── README.md                 # This file
├── requirements.txt          # Python dependencies
├── requirements.yml          # Ansible collections and roles
│
├── apollo/                  # apollo configuration
│   ├── inventory/
│   │   ├── hosts.yml        # Inventory file for apollo
│   │   └── host_vars/       # Host-specific variables
│   └── playbooks/
│       ├── apps.yml         # Application deployment playbook
│       ├── os.yml           # Operating system configuration playbook
│       ├── files/           # Static files for deployment
│       ├── templates/       # Jinja2 templates
│       └── vars/            # Playbook variables
│
└── gravity/                 # gravity configuration
    ├── inventory/
    │   ├── hosts.yml        # Inventory file for gravity
    │   └── host_vars/       # Host-specific variables
    └── playbooks/
        ├── apps.yml         # Application deployment playbook
        ├── os.yml           # Operating system configuration playbook
        ├── files/           # Static files for deployment
        ├── templates/       # Jinja2 templates
        └── vars/            # Playbook variables
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

### Environment Variables

The following environment variables are automatically set when running tasks:

- `PATH` - Includes the virtual environment's bin directory
- `VIRTUAL_ENV` - Points to the project's virtual environment
- `ANSIBLE_COLLECTIONS_PATH` - Path to installed Ansible collections
- `ANSIBLE_ROLES_PATH` - Path to installed Ansible roles
- `ANSIBLE_VARS_ENABLED` - Enables host_group_vars for variable loading

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

