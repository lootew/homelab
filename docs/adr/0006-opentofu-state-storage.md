# 0006. OpenTofu state storage

- Status: Accepted
- Date: 2026-11-08

## Context

OpenTofu keeps a state file that maps resources in code to real objects.
Every `plan` and `apply` reads it, and every `apply` rewrites it.

- The repository is public. State must not be committed: it may contain
  sensitive attributes and changes on every apply.
- A local state file exists in one copy on one workstation and is lost
  together with it.
- Requirements: storage outside the workstation, protection against
  concurrent runs, confidentiality even if storage credentials leak,
  recovery from a bad write, no extra cost.
- The first root module is `terraform/github` (repository settings and
  rulesets). More root modules will follow (for example, the VPS).

## Decision

1. **Backend.** The `s3` backend with the `tofu-state` bucket in Cloud.ru
   Object Storage (S3-compatible, path-style addressing). Each root module
   uses its own key: `<module>/terraform.tfstate`.
2. **Bucket.** Created manually, not by OpenTofu: a bucket cannot be
   described in the state it stores. Versioning is enabled, access is
   private, Object Lock is disabled, a 1 GB quota is set. The settings are
   recorded in this ADR.
3. **Locking.** `use_lockfile = true`: the lock file is created with a
   conditional `PutObject` (`If-None-Match`). Cloud.ru does not document
   this header for `PutObject`, so support was verified by a test on
   2026-11-07: a second concurrent run failed to acquire the lock
   (`412 PreconditionFailed`).
4. **Encryption.** Client-side state and plan encryption: the `pbkdf2` key
   provider and the `aes_gcm` method, `enforced = true`. The passphrase is
   kept in a password manager and passed via `TF_VAR_state_passphrase`.
5. **Access.** A dedicated service account with the `s3e.viewer` and
   `s3e.editor` roles on this bucket only. The access key expires after
   365 days. Credentials are passed via `AWS_ACCESS_KEY_ID` and
   `AWS_SECRET_ACCESS_KEY` and are never written to files.
6. **CI.** CI has no access to state. It runs `tofu fmt -check` and
   `tofu validate` with `-backend=false`. `plan` and `apply` run from the
   workstation only.

## Consequences

Positive:

- State survives the loss of the workstation.
- The storage provider and anyone holding the bucket credentials see only
  ciphertext.
- Concurrent runs cannot overwrite each other's state.
- Previous state versions can be restored from bucket versioning.
- The setup matches the common S3 backend used with AWS.

Negative and risks:

- Losing the passphrase makes the state unreadable. Recovery means
  importing the resources again. Changing the passphrase requires a
  migration with a `fallback` block.
- Locking relies on behaviour the storage provider does not document.
  Repeat the lock test after notable changes on the provider side. If it
  stops working, the impact is limited: one operator, no `apply` in CI.
- The provider console warned about possible upload problems for the
  Standard storage class (2026-11-07). If a state write fails at the end
  of `apply`, OpenTofu saves `errored.tfstate` locally; push it with
  `tofu state push` before running anything else.
- Credentials expire and must be rotated: the S3 access key (365 days)
  and the GitHub token used by the provider.
- The bucket itself is not managed as code.
- Old state versions accumulate; a lifecycle rule for noncurrent versions
  may be needed later.
- Pull requests do not get an automatic `plan`; run it locally.

## Alternatives considered

- **Local state file.** One copy on one workstation, no locking across
  machines.
- **State in Git.** The repository is public, state may contain sensitive
  values, and it changes on every apply.
- **GitLab-managed state (`http` backend).** Repositories and CI are on
  GitHub, which has no built-in state storage; a GitLab account and token
  only for state is an extra dependency.
- **HCP Terraform or similar platforms (`remote` backend).** An external
  platform that also runs `plan`/`apply`; too much for a single-operator
  setup.
- **`pg` or `kubernetes` backend.** Requires a separately managed database,
  or keeps state inside a cluster that OpenTofu itself will manage.
- **Bucket created by a bootstrap OpenTofu module with local state.** Adds
  another state to keep for a single bucket that rarely changes.
- **Server-side encryption only, or no encryption.** The storage provider
  and anyone with bucket credentials could read the state.
- **KMS-backed key provider (`aws_kms`, `gcp_kms`, `openbao`,
  `external`).** Rejected for now. The project does not use AWS or GCP;
  OpenBao would be another stateful service to run and back up; an
  `external` script for another KMS adds custom security-critical code.
  Revisit together with the secrets storage decision.

## References

- OpenTofu S3 backend: https://opentofu.org/docs/language/settings/backends/s3/
- OpenTofu state and plan encryption: https://opentofu.org/docs/language/state/encryption/
