# 💻 Talos Cluster

Instructions on how to spin up a 3-node Kubernetes cluster running [Talos](https://talos.dev)

## ✍ CLI & OS

Install a version of `kubectl` that matches the version of Kubernetes that'll be running in the cluster.  
Follow the [official docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management) on how to do this.

Install the Talos CLI `talosctl` utility:

```bash
sudo curl -L https://github.com/talos-systems/talos/releases/latest/download/talosctl-linux-amd64 \
	-o /usr/local/bin/talosctl
sudo chmod +x /usr/local/bin/talosctl
```

Boot nodes with the ISO or by PXE, images are available in [GitHub releases](https://github.com/talos-systems/talos/releases/latest).

## 🗄 Configuration

Generate configuration files for the cluster:

```bash
talhelper genconfig
```

## 🥾 Bootstrapping

Boot the iso (or pxe), wait for talos to obtain an ip and indicate that address then apply the configuration files to the node:

```bash

```

Repeat this for each node. Once the cluster configuration has been applied, the nodes have rebooted and the `kubelet` healthcheck has passed, the cluster can be bootstrapped. First update the talosconfig file to contain the address of each node:

```bash

```

Then bootstrap the cluster from any of the nodes (just one though!):

```bash
talosctl bootstrap -n <any node ip>
```

Once the cluster is up the kubeconfig file can be downloaded to a safe location, e.g. (`~/.kube/config`):

```bash
talosctl kubeconfig > cluster/kubeconfig
```

## 👆 Upgrading

To [upgrade Kubernetes](https://www.talos.dev/docs/v0.9/guides/upgrading-kubernetes/) I can run the following, which will upgrade Kubernetes across the cluster:

```bash
talosctl -n 10.0.0.11 upgrade-k8s --from 1.20.1 --to 1.20.4
```

To [upgrade Talos](https://www.talos.dev/docs/v0.9/guides/upgrading-talos/) I can run the following for each node:

```bash
talosctl -n <node ip> upgrade \
	--image ghcr.io/talos-systems/installer:vX.YY.ZZ
```

## 🤝 Thanks
