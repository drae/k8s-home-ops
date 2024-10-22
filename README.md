<div align="center">

<img src="https://www.starstreak.net/kube+star.png" align="center" height="150px">

### k8s-home-ops

Management of my home server

</div>

<div align="center">

[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;&nbsp;[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;&nbsp;[![Renovate](https://img.shields.io/github/actions/workflow/status/drae/k8s-home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/drae/k8s-home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.starstreak.net%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)

</div>

## 👋 Overview

This repo contains the gitops workflow for maintaining my [talos](https://talos.dev/) home based server. State storage utilises [topolvm](https://github.com/topolvm/topolvm) and [openebs](https://openebs.io/). NFS is used for accessing data stored on my white box, Ubuntu powered, ZFS backed NAS. 🤖 [Renovate](https://www.mend.io/free-developer-tools/renovate/) and [Github actions](https://github.com/features/actions) are used to automatically open pull requests and perform other "mundane" tasks.

## 💻 Hardware

The single node cluster comprises ~~3 identical~~ a Lenovo M720Q Thinkcentre, specs: Intel Core i5-9500T, 16GB DDR4, 240GB SATA SSD (OS), and 500GB NVME SSD (Data).

Other hardware includes the aging self built NAS (Celeron based, 16GB DDR3, U-NAS 800 case) and, currently, a [Raspberry Pi 4B](https://www.raspberrypi.org/) based router running [OpenWRT](https://openwrt.org).

## 🤔 Before we start

The following applications are used to install and manage the cluster:

- [age](https://github.com/FiloSottile/age)
- [direnv](https://direnv.net/)
- [flux](https://fluxcd.io/docs/installation/)
- [helmfile](https://github.com/helmfile/helmfile)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [sops](https://github.com/mozilla/sops/)
- [task](https://taskfile.dev/)
- [talhelper](https://github.com/budimanjojo/talhelper)

✳️ The repo contains data encrypted using my personal [age](https://github.com/FiloSottile/age) key. You cannot clone this repo and have a functioning cluster. You will need to use your own key (GPG, age, azure keystore, etc.) to re-create and encrypt the existing sops encrypted files (the `*.sops.yaml` files).

## 💾 Installing the cluster

For the k8s "cluster" I use the stable version of [talos](https://talos.dev) as the operating system for running my home cluster. I do not use pxe booting or anything fancy, I burn the [.iso](https://github.com/siderolabs/talos/releases) to a usb and install directly.

## 🥾 Bootstraping the cluster

Much of the remaining installation is automated using [task](https://taskfile.dev/), for a list of available tasks run `task list`, or just type `task`.

✳️ When creating the configuration from scratch, [talhelper](https://github.com/budimanjojo/talhelper) is used to generate the certificates required by `talosctl`. In my case I would type:

```
cd infrastructure/darkstar/talos
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
```

## 💽 Backup and recovery

[volsync](https://github.com/backube/volsync) is used to perform backups of specific persistent volumes to, in my case, Cloudflare R2. I don't maintain local backups, nothing I have is irreplaceable and R2 offers free (and generally quite fast) egress - so reinstalling is "free" and "quick". Backups are performed on a daily schedule.

To simplify the setup of both pvc and an associated volsync _replicationsource_ backup, a series of templates are used, see [/kubernetes/darkstar/apps/storage/volsync/templates](https://github.com/drae/k8s-home-ops/tree/main/kubernetes/darkstar/apps/storage/volsync/templates). The variables used in the templates are automatically substituted by flux during reconciliation. These are defined in the _'fluxtomization'_ for each application, see `ks.yaml` in the root of each applications folder.

For a list of available backup snapshots use `task volsync:list`. You will be prompted for any missing parameters.

Recovery is performed via a `task`, see `task volsync:restore`. One off backups can be performed using `task volsync:snapshot` - note that one off backups are still subject to the retention period for the _replicationsource_! Example, if you have retention set to "retain one per day", performing a one-off backup will replace any other backup performed that day (scheduled or otherwise).

✳️ When doing a restore you have two choices for how the snapshot to be recovered is selected, either "recover the previous X snapshot" or "recover after a given date/time". This can be changed in the volsync taskfile, see [/.taskfiles/volsync/templates/recplicationdestination.tmpl.yaml](https://github.com/drae/k8s-home-ops/tree/main/.taskfiles/volsync/templates/recplicationdestination.tmpl.yaml) - as noted in the comments in the file.

✳️ When doing a cluster (re-)install volsync will do an initial backup of the associated persistent volumes. If you were to immediately restore the volume using the last backup it would obviously would not contain the correct data. Thus, if using the "restore the last X snapshot" option you probably want to set the `previous=` value as "2", to restore the previous bar one backup. There is an open issue on this: "[Option to NOT run backup as soon as replicationsource is applied to the cluster#627](https://github.com/backube/volsync/issues/627)". The current "workaround" for this used by most is volsync's _replicationdestination_ feature. When first creating the pvc, if a backup exists it will immediately attempt to restore it. A new backup is still subsequently performed but at least it will be from the just restored data!

## 👍 Thanks

There exists a great community of small (and not so small!) scale enthusiasts (and professionals) running K8S privately. My repo is based large on many things I have learnt or borrowed from these peeps. Checkout the [k8s@home](https://discord.gg/DNCynrJ) discord, [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes) and other repos for more information.
