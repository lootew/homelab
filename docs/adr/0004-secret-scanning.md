# 4. Secret scanning

Date: 2026-10-29
Status: Accepted

## Context

This repository is public. Anything pushed to it can be read by anyone,
and removing data from Git history afterwards is hard: rewritten commits
can stay reachable in forks, clones and cached views.

Two kinds of data must not be pushed:

- secrets: tokens, keys, passwords;
- personal data: real addresses, phone numbers, names.

## Decision

Use gitleaks in three layers:

1. **pre-commit hook** on the workstation blocks the commit. It can be
   bypassed with `--no-verify` and does not run for edits made in the
   GitHub web interface.
2. **GitHub push protection** blocks pushes that contain supported token
   formats. It does not detect personal data.
3. **CI** runs the same checks after push. It only detects; by then the
   commit is already public. Its purpose is to make a leak visible
   immediately.

Rules are split into two configs, run as two separate gitleaks
invocations:

- `.gitleaks.toml` in this repository: default rules plus generic
  patterns (public IPv4 addresses, phone number formats);
- a config in a private repository: exact values that would themselves
  be a leak if published. CI skips this hook.

`[extend]` is not used to combine them: its path is resolved relative to
the directory gitleaks runs from, not to the config file.

## Alternatives considered

- **Betterleaks.** Successor to gitleaks by the same author, compatible
  with gitleaks configs and flags, and uses tokenization instead of
  entropy. Not adopted yet: the project started in February 2026, and
  the current setup is tested and working. Revisit if gitleaks stops
  receiving security fixes
- **One public config only.** Exact personal values would have to be
  published in the rules that are meant to protect them.

## Consequences

- A leak caught by CI still needs a response: a secret is revoked and
  rotated; personal data requires a history rewrite.
- Work happens in branches, so a leak can be cleaned up without touching
  `main`.
- Go regular expressions do not treat Cyrillic letters as word
  characters, so `\b` cannot be used around Cyrillic values in rules.
- The entropy check can miss low-randomness test values; rules are
  tested with randomly generated tokens.
