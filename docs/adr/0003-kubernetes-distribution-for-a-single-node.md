# 3. Kubernetes distribution for a single node

Date: 2026-10-29
Status: Proposed

## Context

The lab runs on a single VPS with 2 vCPUs and 4 GB of RAM. Workloads:
a Telegram bot, PostgreSQL, a voice server that needs UDP, a metrics
agent and Alertmanager.

The lab is a learning project. Kubernetes, GitOps and operators are
among the skills it is meant to practise, so workloads run on Kubernetes
even though a simpler setup would be enough for them. The goal is to stay
as close to typical production clusters as the budget allows.

Cluster state is fully described in Git and reconciled by a GitOps
controller. Application data is backed up to object storage.

Published minimum requirements for a control plane node:

- kubeadm: 2 CPUs and 2 GB of RAM;
- k3s server: 2 cores and 2 GB of RAM.

## Options

- **kubeadm.** Upstream Kubernetes with etcd. Container runtime, network
  plugin, storage and load balancing are installed and operated
  separately, which is closer to production clusters. There is no
  built-in service load balancer, so exposing UDP on the public address
  needs a separate solution.
- **k3s.** Certified Kubernetes in one binary with a service load balancer,
  local storage and metrics-server included. SQLite datastore by default;
  embedded etcd is available.

## Decision process

Both options will be installed on the node and measured with the same
method: memory used on a clean OS, after installing k3s, and after
installing kubeadm with a network plugin.

kubeadm is preferred if it fits on the node together with the planned
workloads. Otherwise k3s is used.

## Rejected options

- **Docker Compose.** Enough for the workloads, but no GitOps, no
  operators and no Kubernetes practice.
- **minikube.** Built for local development: it runs the cluster inside
  a container or VM on the host, which adds a layer and makes exposing
  public services awkward.
- **Managed Kubernetes.** Does not fit the budget.
- **Multi-node HA.** HA needs at least three control plane nodes, which
  does not fit the budget.
- **MicroK8s.** Uses dqlite instead of etcd by default and is installed
  as a snap, which moves it further from typical clusters than the
  options above.
- **k0s.** Uses upstream components and etcd, but wraps installation and
  operation in its own tooling. kubeadm is the reference way to build
  an upstream cluster, so it is preferred for practice.
