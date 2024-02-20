# 💻 Talos Cluster

## 🥾 Bootstrapping

See the repo [README](https://github.com/drae/k8s-home-ops/) for information on how to setup and bootstrap talos.

## 👆 Upgrading

To [upgrade Kubernetes](https://www.talos.dev/docs/v0.9/guides/upgrading-kubernetes/) I can run the following, which will upgrade Kubernetes across the cluster:

```bash
talosctl -n <NODE IP> upgrade-k8s --from A.BB.C --to A'.BB'.C'
```

To [upgrade Talos](https://www.talos.dev/docs/v0.9/guides/upgrading-talos/) I can run the following for each node:

```bash
talosctl -n <NODE IP> upgrade --image ghcr.io/talos-systems/installer:vX.YY.ZZ
```
