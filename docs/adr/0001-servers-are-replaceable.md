# 1. Servers are replaceable

Date: 2026-10-29
Status: Accepted

## Context

The lab runs on a single small VPS. The current server was configured
by hand: a sudo user, SSH hardening, package cleanup, automatic security
updates.

A new server may still be needed:

- the plan can be upgraded in place, but not downgraded — a smaller plan
  means a new server;
- host failure, account problems or a change of provider;

Rebuilding is expected to be rare. The lab is also a learning project,
and practising infrastructure as code is one of its goals.

## Decision

Servers are treated as replaceable: the full configuration of each server
lives in this repository, and a new server can be built from code alone.

Manual changes on a running server are allowed for debugging, but a change
is not done until it has been moved into code.

Application data is not part of the server. It is kept in backups in
object storage and restored from there.

## Alternatives considered

- **Manual setup with a runbook.** Nothing new to learn, but notes drift
  from reality, and there is no way to check that a rebuilt server
  matches the old one.
- **Disk snapshots.** Fast to restore, but opaque: a snapshot does not
  show what is inside or why, changes cannot be reviewed as a diff, and
  snapshots are tied to one provider.

## Consequences

- A server can be rebuilt from scratch; every change has a history.
- Configuration can be tested locally before it touches the live server.
- Small changes take longer: they go through code first.
- Drift is possible when a manual fix is never moved into code;
  this relies on discipline.
- Backups must be restore-tested on their own, since the server rebuild
  does not cover data.
