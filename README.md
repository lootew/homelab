# homelab

A personal lab for practising SRE and DevOps on a small budget:
infrastructure as code, Kubernetes, GitOps and observability.

Decisions are recorded as [Architecture Decision Records](docs/adr/).
This repository is public; environment-specific and personal data lives
in a separate private repository.

## Status

| Area | Status |
|---|---|
| Workstation (WSL2, Ubuntu 24.04) | Done |
| Leak protection (pre-commit, gitleaks, push protection) | Done |
| CI and branch protection | Done |
| Architecture Decision Records | Ongoing |
| OpenTofu with remote, encrypted state | Planned |
| Server configuration with Ansible | Planned |
| Kubernetes on a single node | Planned |
| GitOps and encrypted secrets | Planned |
| PostgreSQL with backups | Planned |
| Telegram bot deployment | Planned |
| Monitoring and alerting | Planned |
| Voice server | Planned |
| Server provisioning with OpenTofu | Planned |

## Planned architecture

- A single VPS runs Kubernetes; the distribution is chosen by measurement
  ([ADR 0003](docs/adr/0003-kubernetes-distribution.md)).
- Workloads: a Telegram bot with a PostgreSQL backend, a voice server (UDP),
  a metrics agent and Alertmanager.
- Cluster state is reconciled from this repository by a GitOps controller.
  Secrets are stored in Git encrypted with SOPS and age.
- Metrics are shipped over a VPN tunnel to a monitoring host on a separate
  network for long-term storage, alert rules and dashboards.
- Backups and OpenTofu state are kept in S3-compatible object storage.
- Servers are described in code and can be rebuilt from it
  ([ADR 0001](docs/adr/0001-servers-are-replaceable.md)).

## Repository layout

```text
.github/       CI workflow and Dependabot config
docs/adr/      Architecture Decision Records

Planned:
terraform/     OpenTofu: repository settings and servers
ansible/       server configuration
kubernetes/    manifests reconciled by GitOps
bootstrap/     first boot of a new server
```

## Decisions

- [0001 Servers are replaceable](docs/adr/0001-servers-are-replaceable.md)
- [0002 Configuration management with Ansible](docs/adr/0002-configuration-management-with-ansible.md)
- [0003 Kubernetes distribution for a single node](docs/adr/0003-kubernetes-distribution.md) (proposed)
- [0004 Secret scanning](docs/adr/0004-secret-scanning.md)
- [0005 Workstation](docs/adr/0005-workstation.md)

## Development

Requirements: Ubuntu 24.04 (native or WSL2), git and pre-commit.

```bash
git clone https://github.com/lootew/homelab.git
cd homelab
pre-commit install
```

The `gitleaks-private` hook reads a config from the private repository,
cloned next to this one. Without it, commits are blocked; outside this
setup, skip the hook with `SKIP=gitleaks-private`.

CI runs on every pull request and on pushes to `main`: the pre-commit hooks
and a gitleaks scan of the full Git history. `main` accepts changes only
through pull requests with both checks passing.

## Public content policy

- No secrets, real addresses, phone numbers or personal data, apart from
  the copyright holder in `LICENSE`.
- Examples use documentation address ranges from RFC 5737:
  `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`.
- Environment-specific values (inventory, real addresses) live in the
  private repository.
- How this is enforced: [ADR 0004](docs/adr/0004-secret-scanning.md).

## License

[MIT](LICENSE)
