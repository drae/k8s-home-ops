# Copilot Instructions for k8s-home-ops

## Overview

This repository manages a Talos-based Kubernetes home server using GitOps with Flux. The cluster is named "darkstar" and runs on a single Lenovo M720Q node.

## Task Runner Commands

All operations use [Task](https://taskfile.dev/). Run `task` or `task list` to see available tasks.

### Bootstrap & Setup

```bash
# Initial environment setup (installs mise, doppler, and tools)
task bootstrap:setup

# Bootstrap Talos cluster from scratch
task bootstrap:talos

# Bootstrap Flux and install CRDs and apps
task bootstrap:flux
```

### Talos Operations

```bash
# Generate Talos cluster configuration
task talos:genconfig

# Apply configuration to cluster nodes
task talos:applyconfig

# Generate kubeconfig
task talos:kubeconfig

# Upgrade a specific node
task talos:upgrade-node NODE=<hostname>

# Reset a node to maintenance mode
task talos:reset HOSTNAME=<hostname>
```

### Flux Operations

```bash
# Build/apply/delete a Flux Kustomization
task flux:build-ks DIR=<path>
task flux:apply-ks DIR=<path>
task flux:delete-ks DIR=<path>

# Suspend/resume all Kustomizations
task flux:suspend-ks-all
task flux:resume-ks-all

# Sync all HelmReleases
task flux:sync-all-hr
```

### Volsync Backup Operations

```bash
# List backup snapshots for an app
task volsync:list APP=<name> NS=<namespace>

# Create a manual snapshot
task volsync:snapshot APP=<name> NS=<namespace>

# Snapshot all apps (non-blocking)
task volsync:snapshot-all

# Restore from backup
task volsync:restore APP=<name> NS=<namespace> PREVIOUS=<snapshot-id>

# Unlock all restic repositories
task volsync:unlock
```

## Architecture

### Directory Structure

- **`infrastructure/`** - Talos cluster configuration
  - `talos/darkstar/` - Talos config files, talhelper configs, and generated cluster configs
- **`kubernetes/darkstar/`** - Kubernetes manifests and GitOps configs
  - `apps/` - Application deployments organized by category (home-automation, media, database, etc.)
  - `components/` - Reusable Kustomize components (e.g., volsync templates)
  - `flux/` - Flux CD configuration and Helm/OCI repository definitions
  - `.bootstrap/` - Bootstrap resources for initial cluster setup

### Key Technologies

- **OS**: Talos Linux with SecureBoot
- **GitOps**: Flux CD for continuous deployment
- **Storage**: 
  - TopoLVM for local volumes (thin provisioning)
  - OpenEBS for additional storage
  - NFS mounts for ZFS-backed NAS data
- **Backups**: Volsync with Restic to NFS mount (6-hourly schedule, 24 hourly + 7 daily retention)
- **Secrets**: Doppler for secrets management, External Secrets Operator for K8s integration
- **Tool Management**: mise for version management

### App Deployment Pattern

Each app follows this structure:
```
apps/<namespace>/<app-name>/
├── ks.yaml              # Flux Kustomization
└── app/
    ├── helmrelease.yaml # Helm chart deployment
    └── kustomization.yaml
```

**Note**: The `<namespace>` folder name is the actual Kubernetes namespace where the app deploys (e.g., `home-automation`, `media`, `database`).

The `ks.yaml` file:
- References the GitOps repository
- Defines dependencies on other apps/infrastructure
- Sets substitution variables for volsync templates via `postBuild.substitute`
- Can include volsync component via `components: - ../../../../components/volsync`

### Volsync Integration

Apps using persistent storage can enable automated backups by:

1. Including the volsync component in `ks.yaml`:
   ```yaml
   components:
     - ../../../../components/volsync
   ```

2. Setting substitution variables in `ks.yaml`:
   ```yaml
   postBuild:
     substitute:
       APP: <app-name>
       VOLSYNC_CLAIM: <pvc-name>
       # Optional overrides:
       APP_UID: "2000"
       APP_GID: "2000"
       VOLSYNC_CACHE_CAPACITY: "1Gi"
       VOLSYNC_STORAGECLASS: "topolvm-thin-provisioner"
   ```

The volsync component templates (`kubernetes/darkstar/components/volsync/nfs/`) define:
- **PVC** - If needed (can reference existing)
- **ReplicationSource** - Backup job with restic to NFS
- **ReplicationDestination** - Used during restore operations
- **ExternalSecret** - Pulls NFS repository path and restic password from Doppler

A **MutatingAdmissionPolicy** automatically injects NFS volume mounts into volsync job pods:
- Targets jobs with `volsync-` name prefix and `app.kubernetes.io/created-by: volsync` label
- Adds NFS volume: `server: 10.1.10.10, path: /mnt/zstore/backup/volsync`
- Mounts at `/repository` in the mover container

Default backup schedule: `0 */6 * * *` (every 6 hours)  
Default retention: 24 hourly + 7 daily snapshots, pruned every 7 days

## Conventions

### Flux Kustomization Dependencies

Always specify dependencies in `ks.yaml` to ensure proper ordering:
- Storage apps depend on `topolvm` and `volsync` in `storage` namespace
- Apps with backups depend on `volsync`
- Apps using databases depend on the relevant DB in `database` namespace

### Security Context

Standard pod security for non-privileged apps:
```yaml
runAsNonRoot: true
runAsUser: 2000
runAsGroup: 2000
fsGroup: 2000
fsGroupChangePolicy: OnRootMismatch
seccompProfile:
  type: RuntimeDefault
```

### Namespace Organization

Apps are organized into namespaces by function. The folder structure under `apps/` mirrors the namespace structure:

- `apps/home-automation/` → `home-automation` namespace - Home Assistant, Zigbee2MQTT, ESPHome, etc.
- `apps/media/` → `media` namespace - Plex, *arr apps, download clients
- `apps/database/` → `database` namespace - PostgreSQL, Redis, Mosquitto MQTT
- `apps/storage/` → `storage` namespace - TopoLVM, Volsync, OpenEBS
- `apps/networking/` → `networking` namespace - Ingress, certificates, external access
- `apps/kube-system/` → `kube-system` namespace - Core cluster services
- `apps/flux-system/` → `flux-system` namespace - Flux controllers and configurations

### Variable Substitution

Flux Kustomizations support variable substitution using `${VAR_NAME}` syntax. Variables are defined in the `postBuild.substitute` section of `ks.yaml` and are automatically replaced in referenced manifests.

Common variables:
- `APP` - Application name (used in volsync templates)
- `VOLSYNC_CLAIM` - PVC name for backup
- `APP_UID` / `APP_GID` - User/group IDs for file permissions
- Storage class and snapshot class overrides

### HelmRelease Pattern

Use `chartRef` to reference OCI repositories defined in `flux/repos/`:
```yaml
chartRef:
  kind: OCIRepository
  name: app-template
  namespace: flux-system
```

## Secrets Management

- **Doppler** provides secrets for Talos config generation and bootstrap
- **External Secrets Operator** syncs secrets from Doppler to Kubernetes
- Projects: `darkstar` (K8s apps), `talos` (Talos configs)
- Never commit secrets - they're injected at runtime via `doppler run`

## Testing Individual Apps

To test changes to a single app without full cluster sync:

```bash
# Build the Kustomization locally
task flux:build-ks DIR=home-automation/zigbee2mqtt

# Apply it to the cluster
task flux:apply-ks DIR=home-automation/zigbee2mqtt
```

## Recovery Scenarios

### Restore a Single App

1. List available snapshots:
   ```bash
   task volsync:list APP=zigbee2mqtt NS=home-automation
   ```

2. Restore from specific snapshot:
   ```bash
   task volsync:restore APP=zigbee2mqtt NS=home-automation PREVIOUS=<snapshot-id>
   ```
   
   This will:
   - Suspend the Flux Kustomization and HelmRelease
   - Scale down the app
   - Restore data from snapshot
   - Resume Flux and reconcile
   - Wait for app to be ready

### Full Cluster Recovery

1. Reinstall Talos on hardware
2. Bootstrap cluster: `task bootstrap:talos && task bootstrap:flux`
3. Flux will automatically deploy all apps
4. Restore individual app data as needed using volsync

## Notes

- The cluster uses a single node configuration (previously was 3-node)
- NFS is mounted from a separate Ubuntu/ZFS NAS
- Backups are stored on NFS share (10.1.10.10:/mnt/zstore/backup/volsync) from the Ubuntu/ZFS NAS
- Renovate automatically opens PRs for dependency updates
- All tools are version-managed via `.mise.toml`
