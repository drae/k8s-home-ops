<div align="center">

<img src="https://www.starstreak.net/kube+star.png" align="center" height="150px">

### k8s-home-ops

Flux management of my home cluster

</div>

<div align="center">

[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/drae/k8s-home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/drae/k8s-home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;

</div>

## 👋 Overview

This repo contains my flux2 based gitops workflow for maintaining my [talos](https://talos.dev/) home cluster. Storage for stateful containers utilises [topolvm](https://github.com/topolvm/topolvm) and [openebs](https://openebs.io/). NFS is used for accessing data stored on my white box, Ubuntu powered, ZFS backed NAS.

🤖 [Renovate](https://www.mend.io/free-developer-tools/renovate/) and [Github actions](https://github.com/features/actions) are used to automatically open pull requests, produce diffs, and do security checks for updated charts, images, and other resources.

The following applications are used to install and manage the cluster:

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [helm](https://helm.sh/)
- [kustomize](https://kustomize.io/)
- [flux](https://fluxcd.io/docs/installation/)
- [sops](https://github.com/mozilla/sops/)
- [direnv](https://direnv.net/)
- [task](https://taskfile.dev/)
- [talhelper](https://github.com/budimanjojo/talhelper)

## 💻 Hardware

The single node cluster comprises ~~3 identical~~ a Lenovo M720Q Thinkcentre, specs: Intel Core i5-9500T, 16GB DDR4, 240GB SATA SSD (OS), and 500GB NVME SSD (Data).

Other hardware includes an aging self built NAS (Celeron based, 16GB DDR3 in a neat U-NAS 800 case) and, currently, a [Raspberry Pi 4B](https://www.raspberrypi.org/) router running [OpenWRT](https://openwrt.org).

The Pi replaces an older Atom based self-built router who's external PSU went 💥 after many years of service. Given that router pulled nearly 20W, and with rising energy costs in mind, I thought I'd try the Pi 4. It works surprisingly well - and sips power.

Total power use (inc. switch, zigbee transceivers, modem, etc.) varies from around **66-80W** (with disks spundown and cluster idling), **105-115W** with [Plex](https://plex.tv) direct playing or (hardware) transcoding, to **130-150W** when the cluster/NAS are particularly busy (scrubing, etc.). I would say it averages out over 24 hours to probably **90-110W**.

## 🤔 Before we start

The repo has lots of encrypted data that is tied to my AGE private key. You cannot simply clone this repo, follow this walkthrough, and have a functioning cluster. You will need to use your own key (GPG, age, azure keystore, etc.), update the `.sops.yaml` file in the root of the repo, replacing my age key(s) with your own key.

Then you will need to re-create all the individual `XXXXX.sops.yaml` files in the repo (`infrastructure/*` and `cluster/*`) with your own data and encrypt them with your own key.

Creating your own key is "out of scope" for this readme, a quick [google](https://www.google.com/) will get you sorted!

## 💾 Installing the cluster

Clone the repo, change to the new folder and run `direnv allow` to enable the loading of certain environment variables:

```
git clone https://github.com/drae/k8s-home-ops.git && cd k8s-home-ops && direnv allow
```

I use the stable version of [talos](https://talos.dev) as the operating system for running my home cluster. I do not use pxe booting or anything fancy, I burn the [.iso](https://github.com/siderolabs/talos/releases) to a usb and install directly.

[talhelper](https://github.com/budimanjojo/talhelper), a great tool by [budimanjojo](https://github.com/budimanjojo/) simplifies creation of the necessary configuration. From scratch run:

```
cd infrastructure/talos
talhelper gensecret --patch-configfile > talenv.sops.yaml
sops -e -i talenv.sops.yaml
talhelper genconfig
cd ../..
```

Unless the secrets are updated, future updates of the configuration only requires `talhelper genconfig` to be run.

All the necessary node and talosconfig files are created in the `infrastructure/talos/clusterconfig` folder. Note that I add additional parameters to the `talenv.sops.yaml` file, see the `talconfig.yaml` for more info (look for variables of the form `${<VAR NAME>}` and replicate any missing in talenv file with relevant values).

I then apply the configuration to each prepared node (i.e. booted with the talos usb flash drive):

```
talosctl -n <NODE IP> apply-config infrastructure/talos/clusterconfig/<NODE CONFIG>.yaml --insecure
```

Then sit back and watch the node prepare itself, rinse and repeat for all the nodes. With the nodes prepared it is time to issue the bootstrap command to just one of the nodes:

```
talosctl -n <NODE IP> bootstrap
```

This initiates the installation of kubernetes cluster wide. Once bootstraped I can download the `kubeconfig`:

```

```

and apply a "temporary" CNI configuration (I use [cilium](https://cilium.io/) as my CNI) and the csr auto approver. This is just enough configuration to enable networking (full configuration is managed by flux):

```

```

Doing it this way ensures all the relevant helm annotations are included in the manifest. Without these flux will fail to take over management of the installation. With this complete that should be it, cluster is ready 🎉🎉🎉

✳️ See the following folder for more details on the talos configuration: [/infrastructure/talos](https://github.com/drae/k8s-home-ops/tree/main/infrastructure/talos). Note that sops is used to encrypt some of the more sensitive information!

~~✳️ I use [haproxy](https://haproxy.org) as the load balancer for both the talos and kubernetes control planes. Previously I have used the [shared layer-2 vip](https://www.talos.dev/v1.1/introduction/getting-started/#decide-the-kubernetes-endpoint) method but it can sometimes throw a fit that is difficult or even impossible to recover from (probably due to my lack of knowledge and pushing capabilities). An example configuration for haproxy can be found [here](https://gist.github.com/drae/1208b28545c3c164e10e05915b36bfcc)~~

## 🥾 Bootstraping the cluster

Create the flux-system namespace:

```
kubectl create namespace flux-system
```

Export the SOPS secret key from GPG and import to the cluster:

```
gpg --export-secret-keys --armor "<GPG>" | kubectl create secret \
  generic sops-gpg --namespace=flux-system --from-file=sops.asc=/dev/stdin
```

The above commands can also be invoked using `task`:

```
task cluster:bootstrap-sops KEY=<GPG>
```

where `GPG` is the relevant key from your gpg keyring. If you do not specify a key mine will be used (and will fail because you do not have my private key ... I hope!).

If this is a new installation or no pre-existing github token is available run (replacing `<REPO URL>` as appropriate):

```
flux create source git flux-system --url=<REPO URL> --branch=main -n flux-system
```

Now apply the flux manifests using kustomize:

```
kubectl apply -k cluster/base/flux-system
```

This will need to be run twice due to race conditions. Sit back and watch the cluster install itself, magic 🪄.

## 💽 Backup and recovery

## 🤝 Thanks

There exists a great community of small (and not so small!) scale enthusiasts (and professionals) running K8S privately. My repo is based large on many things I have learnt or borrowed from these peeps. Checkout the [k8s@home](https://discord.gg/DNCynrJ) discord, [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes) and other repos for more information.
