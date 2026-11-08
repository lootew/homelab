# Runbook: restore a deleted GitHub repository

Repository settings and the `main-protection` ruleset are defined in
`terraform/github`. The Git history is restored from a local clone.

The order matters: the ruleset blocks direct pushes to `main`, so the
history must be pushed before the ruleset is created.

1. Load credentials: `source scripts/opentofu-env.sh`.
2. `cd terraform/github && tofu plan`. Expected: the repository and the
   ruleset will be created (OpenTofu sees that they no longer exist).
3. Create only the repository:

   ```bash
   tofu plan -target=github_repository.homelab -out=restore.tfplan
   tofu apply restore.tfplan
   rm restore.tfplan
   ```

   The repository is created empty: no initial commit, README or licence,
   so the local history can be pushed as is.

4. Push the history from a local clone:

   ```bash
   git push origin main
   ```

5. Create the rest (the ruleset):

   ```bash
   tofu plan -out=restore.tfplan
   tofu apply restore.tfplan
   rm restore.tfplan
   ```

6. `tofu plan` must show `No changes`.

The ruleset gets a new ID; nothing in the code depends on it.

Secret scanning and push protection are part of the repository settings
in code and are restored with the repository. Issues, pull requests and
Actions history are not restored.
