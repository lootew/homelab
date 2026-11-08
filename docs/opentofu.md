# Working with OpenTofu

How state is stored and why: [ADR 0006](adr/0006-opentofu-state-storage.md).
Maintenance and recovery: [runbooks](runbooks/).

## Prerequisites

- OpenTofu 1.13.x. CI uses the same version; when upgrading, change the
  workstation and `.github/workflows/checks.yml` (version and checksum)
  together.
- Access to the state bucket: the service account access key described in
  ADR 0006.
- The state encryption passphrase.
- For `terraform/github`: a fine-grained GitHub personal access token
  limited to the managed repositories, with repository permissions
  **Administration: Read and write** and **Metadata: Read-only**.

All secrets are kept in a password manager and are never written to files.

## Credentials for a shell session

```bash
source scripts/opentofu-env.sh
```

The script asks for each value without echoing it and exports:

| Variable | Used by |
|---|---|
| `AWS_ACCESS_KEY_ID` | S3 backend (format `<tenant_id>:<key_id>`) |
| `AWS_SECRET_ACCESS_KEY` | S3 backend |
| `TF_VAR_state_passphrase` | state and plan encryption |
| `GITHUB_TOKEN` | GitHub provider |

Leave a prompt empty to skip a variable. The values live only in the
current shell: close the terminal when done. Do not set `GITHUB_OWNER`: the
provider lets it override `owner` from the configuration.

## First run in a module

```bash
cd terraform/github
tofu init
tofu plan    # expected on a clean checkout: No changes
```

## Making a change

Changes are applied from `main` after the pull request is merged, so `main`
always describes what is applied or about to be applied.

1. Branch from a fresh `origin/main`:

   ```bash
   git fetch
   git switch -c <branch> origin/main
   ```

2. Edit the code, then check it:

   ```bash
   tofu fmt -recursive
   tofu plan
   ```

3. Open a pull request. Describe the expected plan in the description
   (for example, `0 to add, 1 to change, 0 to destroy` and what changes).
   CI runs `tofu fmt` and `tofu validate`; it has no access to state.
4. Merge with squash.
5. Apply from `main`, using a saved plan:

   ```bash
   git switch main
   git pull
   cd terraform/github
   tofu plan -out=change.tfplan
   # review the plan: it must match the pull request
   tofu apply change.tfplan
   rm change.tfplan
   ```

Rules:

- Apply only a saved plan (`-out`), never a plan rebuilt by `apply`.
- Never commit `*.tfstate` or `*.tfplan` files; both are ignored by Git.
- Repositories have `prevent_destroy`: any plan that deletes or replaces
  them fails. Remove the guard only on purpose, in a separate change.

## Importing existing resources

1. Add `import` blocks to a temporary `imports.tf`.
2. Generate a draft: `tofu plan -generate-config-out=generated.tf`.
3. Move the resources into the module files and drop noise (computed
   attributes such as `etag`, create-only attributes). Removing an
   attribute means "use the provider default", not "leave as is": remove
   one or two at a time and re-run `tofu plan`.
4. When the plan shows only imports (`N to import, 0 to add, 0 to change,
   0 to destroy`), apply it as a saved plan and delete `imports.tf`.
