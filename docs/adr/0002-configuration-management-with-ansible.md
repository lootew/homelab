# 2. Configuration management with Ansible

Date: 2026-10-29
Status: Accepted

## Context

Per ADR 0001, server configuration must live in code. After first boot,
a server needs a sudo user, SSH hardening, removal of unneeded packages,
automatic security updates and a Kubernetes distribution.

This configuration must be safe to re-apply to a server that is already
configured, and it should be possible to see what will change before
applying it.

Ansible connects over SSH, so it needs a user and a key that already
exist on the server. How a new server gets them on first boot is
a separate problem and will be covered by its own ADR.

## Decision

Server configuration is managed with Ansible.

- Playbooks are run from the workstation over SSH.
- Roles: a base role (users, SSH, packages, updates) and a k3s role.
  The k3s role wraps the official installer with a pinned version, so
  the installation is reproducible and not a manual step.
- The base role must have a Molecule test (converge, idempotence, verify)
  before it is applied to a live server: a mistake there can lock out
  SSH access. Other roles get Molecule tests where practical.
- The first run against an existing server is done with `--check --diff`.
- CI runs syntax checks and linting only; it has no access to servers.

## Alternatives considered

- **Shell scripts.** No new tool, but idempotency has to be written by
  hand for every step, there is no dry run, and scripts are hard to test.
- **cloud-init for everything.** Runs only on first boot, so it cannot
  change a server that is already running.
- **Agent-based tools (Puppet, Chef, Salt).** Designed around a pull model
  for fleets of machines, usually with a central server and an agent on
  every node. For a single node this adds services and resource usage
  without a matching benefit.

## Consequences

- Changes can be previewed with `--check --diff` and re-applied safely.
- The base role is tested in a disposable container before it touches
  the live server.
- Containers do not fully match a real VM (systemd, kernel), so some
  behaviour, including k3s, is only verified on a real server.
- Deployment depends on the workstation. Running playbooks from CI is
  possible later; it would need SSH access from CI to the server and
  will get its own ADR.
