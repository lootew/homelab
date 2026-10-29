# 5. Workstation

Date: 2026-10-29
Status: Accepted

## Context

All work on the lab is done from one workstation: editing code, running
OpenTofu and Ansible, local tests with k3d and Molecule, and SSH access
to the server.

Two machines were available: a Windows laptop with 16 GB of RAM and an
Intel Mac with 8 GB. Homebrew moved Intel macOS to Tier 3 in September
2026 (no CI, no new bottles) and plans to stop running on Intel Macs
in September 2027.

Tools behave differently across operating systems and versions, so
differences between the workstation, CI and the server are a source of
"works on my machine" failures.

## Decision

- Work is done inside **WSL2 with Ubuntu 24.04** on the Windows laptop.
  Project files live in the WSL filesystem, not on the Windows drive.
- **The same Ubuntu LTS** runs on the workstation, in CI and on the
  server. CI pins `runs-on: ubuntu-24.04` instead of `ubuntu-latest`.
  The three are upgraded to a new LTS together, as one planned change.
- **SSH private keys are not stored on disk.** They live in a password
  manager with a built-in SSH agent; each use requires confirmation on
  the host. WSL reaches the agent through a bridge, and `~/.ssh` holds
  only public keys.
- Git talks to GitHub over HTTPS with the GitHub CLI token. Commits use
  the GitHub noreply address.
- The Intel Mac stays as a backup machine.

## Alternatives considered

- **Intel Mac as the main workstation.** Less memory for local clusters,
  and Homebrew support for Intel is ending.
- **Native Windows tooling.** Different shell and paths from CI and the
  server; most of the tools are Linux-first.
- **Private keys as passphrase-protected files.** A standard approach,
  but the key file can be copied from disk; with an agent, the key never
  leaves the password manager.
- **`ubuntu-latest` in CI.** The label moves to new Ubuntu releases on
  GitHub's schedule (it is moving from 24.04 to 26.04 between October
  and November 2026), which would break parity without notice.

## Consequences

- Local results match CI and the server more closely.
- Moving to a new Ubuntu LTS is a deliberate step across all three.
- SSH access depends on the password manager being available on the
  workstation.
- The agent exposes the keys of both machines, so if the workstation or
  the password manager is compromised, both keys must be revoked.
