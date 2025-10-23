# Docker Compose Service Role

This Ansible role deploys and manages Docker Compose applications as systemd services.

## Features

- Deploys docker-compose files to target hosts
- Creates systemd service units for reliable service management
- Handles service restarts on configuration changes
- Supports health checks and custom systemd options
- Follows Ansible best practices with proper handlers and idempotency

## Requirements

- Docker and docker-compose installed on target hosts
- systemd-based Linux distribution
- Ansible 2.9+

## Role Variables

### Required Variables

- `service_name`: Name of the service (used for directory name and systemd service name)

### Optional Variables

All variables are prefixed with `docker_compose_service_` and have sensible defaults:

```yaml
# Base directory where docker-compose projects are stored
docker_compose_service_base_dir: "/opt/docker"

# File ownership
docker_compose_service_user: "{{ ansible_user }}"
docker_compose_service_group: "users"

# File permissions
docker_compose_service_file_mode: "0775"
docker_compose_service_systemd_file_mode: "0644"

# Systemd service configuration
docker_compose_service_condition_path_is_mount_point: "/"
docker_compose_service_enabled: true
docker_compose_service_state: started
docker_compose_service_restart_on_change: true

# Systemd dependencies
docker_compose_service_wants: []
docker_compose_service_after: ["docker.service"]
docker_compose_service_requires: ["docker.service"]

# Health checks
docker_compose_service_health_check_enabled: false
docker_compose_service_health_check_delay: 10
```

### Docker Compose File Source

By default, the role looks for docker-compose files at:
`files/docker-compose/{{ service_name }}/docker-compose.yml`

You can override this with:
```yaml
docker_compose_file_src: "path/to/your/docker-compose.yml"
```

## Usage Examples

### Basic Usage

```yaml
- name: Deploy smartctl-exporter
  include_role:
    name: docker_compose_service
  vars:
    service_name: smartctl-exporter
```

### Advanced Usage

```yaml
- name: Deploy application with custom settings
  include_role:
    name: docker_compose_service
  vars:
    service_name: my-app
    docker_compose_service_base_dir: "/srv/docker"
    docker_compose_service_health_check_enabled: true
    docker_compose_service_wants: ["network-online.target"]
    docker_compose_file_src: "custom-path/docker-compose.yml"
```

### Multiple Services

```yaml
- name: Deploy multiple services
  include_role:
    name: docker_compose_service
  vars:
    service_name: "{{ item }}"
  loop:
    - smartctl-exporter
    - sabnzbd
    - qbittorrent
```

## File Structure

The role expects the following structure in your playbook:

```
playbooks/
├── files/
│   └── docker-compose/
│       ├── smartctl-exporter/
│       │   └── docker-compose.yml
│       ├── sabnzbd/
│       │   └── docker-compose.yml
│       └── qbittorrent/
│           └── docker-compose.yml
└── your-playbook.yml
```

## Systemd Integration

The role creates systemd services with these features:

- **Automatic startup**: Services start on boot
- **Dependency management**: Waits for Docker to be ready
- **Health checks**: Optional container health verification
- **Reload support**: `systemctl reload docker-compose@service` pulls and restarts
- **Proper cleanup**: Graceful shutdown with `docker compose down`

## Service Management

After deployment, you can manage services using standard systemd commands:

```bash
# Check status
systemctl status docker-compose@smartctl-exporter

# Restart service
systemctl restart docker-compose@smartctl-exporter

# View logs
journalctl -u docker-compose@smartctl-exporter -f

# Pull new images and restart
systemctl reload docker-compose@smartctl-exporter
```