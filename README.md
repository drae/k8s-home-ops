<div align="center">

<img src="https://www.starstreak.net/kube+star.png" align="center" height="150px" alt="logos">

### k8s-home-ops

Management of my home server

</div>

## 👋 Overview

This repo contains the gitops workflow for maintaining my [talos](https://talos.dev/) based home server. State storage utilises [topolvm](https://github.com/topolvm/topolvm) and [openebs](https://openebs.io/). NFS is used for accessing data stored on my white box, Ubuntu powered, ZFS backed NAS. 🤖 [Renovate](https://www.mend.io/free-developer-tools/renovate/) and [Github actions](https://github.com/features/actions) are used to automatically open pull requests and perform other "mundane" tasks.

## 💻 Hardware

The single node cluster comprises ~~3 identical~~ a Lenovo M720Q Thinkcentre, specs: Intel Core i5-9500T, 16GB DDR4, 240GB SATA SSD (OS), and 500GB NVME SSD (Data).

Other hardware includes the aging self built NAS (Celeron based, 16GB DDR3, U-NAS 800 case) and, currently, a [Raspberry Pi 4B](https://www.raspberrypi.org/) based router running [OpenWRT](https://openwrt.org).

## 🤔 Before we start

The following applications are used to install and manage the cluster:

- [mise](https://github.com/jdx/mise) - tool management
- [doppler](https://www.doppler.com/) - secrets management
- [task](https://taskfile.dev/) - task runner

Everything else can be installed via task and mise. The easy way is to run:

```sh
task bootstrap:setup
```

This will install all the additional tools which include:

- [flux](https://fluxcd.io/docs/installation/)
- [helmfile](https://github.com/helmfile/helmfile)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [talhelper](https://github.com/budimanjojo/talhelper)

## 💾 Installing the cluster

For the k8s "cluster" I use the stable version of [talos](https://talos.dev) as the operating system for running my home cluster. I do not use pxe booting or anything fancy, I burn an [.iso](https://factory.talos.dev/) to a usb and install directly. I currently use secureboot which can add a [few extra steps](https://www.talos.dev/v1.11/talos-guides/install/bare-metal-platforms/secureboot/).

## 🥾 Bootstraping the cluster

Bootstraping the installation is automated using [task](https://taskfile.dev/), for a list of available tasks run `task list`, or just type `task`. A consolidated install can be achieved using:

```sh
task bootstrap:talos
task bootstrap:flux
```

This will ensure everything that is needed for installation exists, apply the configuration and bootstrap talos, install CRDs and finally kick off cluster installation via fluxcd.

## 💽 Backup and recovery

[volsync](https://github.com/backube/volsync) is used to perform backups of specific persistent volumes to, in my case, Cloudflare R2. I don't maintain local backups, nothing I have is irreplaceable and R2 offers free (and generally quite fast) egress - so reinstalling is "free" and "quick". Backups are performed on a daily schedule.

To simplify the setup of both pvc and an associated volsync _replicationsource_ backup, a series of templates are used, see [/kubernetes/darkstar/apps/storage/volsync/templates](https://github.com/drae/k8s-home-ops/tree/main/kubernetes/darkstar/apps/storage/volsync/templates). The variables used in the templates are automatically substituted by flux during reconciliation. These are defined in the _'fluxtomization'_ for each application, see `ks.yaml` in the root of each applications folder.

For a list of available backup snapshots use `task volsync:list` - you will be prompted for any missing parameters.

Recovery is performed via a `task`, see `task volsync:restore`. One off backups can be performed using `task volsync:snapshot` - note that one off backups are still subject to the retention period for the _replicationsource_! Example, if you have retention set to "retain one per day", performing a one-off backup will replace any other backup performed that day (scheduled or otherwise).

## 👍 Thanks

There exists a great community of small (and not so small!) scale enthusiasts (and professionals) running K8S privately. My repo is based large on many things I have learnt or borrowed from these peeps. Checkout the [k8s@home](https://discord.gg/DNCynrJ) discord, [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes) and other repos for more information.
