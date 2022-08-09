# 💻 Talos Cluster

Instructions on how to spin up a 3-node Kubernetes cluster running [Talos](https://talos.dev)
Almost everything in here is based on the official ["Getting Started"](https://talos.dev/docs/v0.9/introduction/getting-started) guide, with some modifications.

## ✍ CLI & OS

Install a version of `kubectl` that matches the version of Kubernetes that'll be running in the cluster.  
Follow the [official docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management) on how to do this.

Install the Talos CLI `talosctl` utility:

```bash
sudo curl -L https://github.com/talos-systems/talos/releases/latest/download/talosctl-linux-amd64 \
	-o /usr/local/bin/talosctl
sudo chmod +x /usr/local/bin/talosctl
```

Install `jq` and `yq`:

```bash
sudo apt install jq
sudo curl -L https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 -o /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
```

Boot nodes with the ISO or by PXE, images are available in [GitHub releases](https://github.com/talos-systems/talos/releases/latest).

## 🗄 Configuration

Generate configuration files for the cluster:

```bash
talosctl gen config <cluster name> <cluster endpoint>
```

`<cluster name>` is the arbitrary name for the cluster, `<cluster endpoint>` is the endpoint for it, can be a domain name or an IP (if domain name make sure it is resolveable by the nodes). The endpoint can be a single nodes ip, the addresses of the load balancer behind which the nodes sit or a [virtual ip](https://www.talos.dev/docs/v0.10/guides/vip/). This is what I am using.

Merge in the overrides.yaml using `yq`:

```bash
for f in controlplane join; do
	yq -Pi ea '. as $item ireduce ({}; . * $item )' $f.yaml overrides.yaml
done
```

## 🥾 Bootstrapping

Boot the iso (or pxe), wait for talos to obtain an ip and indicate that address then apply the configuration files to the node:

```bash
talosctl apply-config -i --nodes <node ip> --file controlplane.yaml
```

Repeat this for each node. Once the cluster configuration has been applied, the nodes have rebooted and the `kubelet` healthcheck has passed, the cluster can be bootstrapped. First update the talosconfig file to contain the address of each node:

```bash
talosctl config endpoint <the ip address of each node - space separated>
```

Then bootstrap the cluster from any of the nodes (just one though!):

```bash
talosctl bootstrap -n <any node ip>
```

Once the cluster is up the kubeconfig file can be downloaded to a safe location, e.g. (`~/.kube/config`):

```bash
talosctl kubeconfig
```

## 👆 Upgrading

To [upgrade Kubernetes](https://www.talos.dev/docs/v0.9/guides/upgrading-kubernetes/) I can run the following, which will upgrade Kubernetes across the cluster:

```bash
talosctl -n 10.0.0.11 upgrade-k8s --from 1.20.1 --to 1.20.4
```

To [upgrade Talos](https://www.talos.dev/docs/v0.9/guides/upgrading-talos/) I can run the following for each node:

```bash
talosctl -n <node ip> upgrade \
	--image ghcr.io/talos-systems/installer:v0.10.0
```

## 🤝 Thanks

This guide has been shamelessly copied from [p3lim](https://github.com/p3lim/rudder) and modified to how I do things (too lazy to write my own readme in full!)
