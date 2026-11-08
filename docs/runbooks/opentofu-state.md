# Runbook: OpenTofu state problems

Context: [ADR 0006](../adr/0006-opentofu-state-storage.md).
Load credentials first: `source scripts/opentofu-env.sh`.

## State lock is stuck

Symptom: `Error acquiring the state lock`, but no other OpenTofu run is
active (for example, a previous run was killed).

1. Make sure no other `tofu` process is running, in any terminal.
2. Take the lock ID from the error message (`Lock Info: ID: ...`).
3. Release the lock:

   ```bash
   tofu force-unlock <LOCK_ID>
   ```

Never force-unlock while another run may still be writing state.

## State write failed at the end of apply

Symptom: `apply` changed resources but failed to upload state;
`errored.tfstate` appeared in the module directory.

1. Do not run any other OpenTofu command first.
2. Push the saved state:

   ```bash
   tofu state push errored.tfstate
   ```

3. Check with `tofu plan`: it should show no changes for what was just
   applied.
4. Delete `errored.tfstate`. It is ignored by Git and must not be
   committed.

If the upload keeps failing, see the storage notes in ADR 0006 (storage
class) and debug with `TF_LOG=debug`.

## State is corrupted or was overwritten

The bucket keeps previous versions of every state object.

1. In the storage console, open the bucket, find
   `<module>/terraform.tfstate` and list its versions.
2. Make the last good version current (restore it, or copy that version
   over the current object).
3. Run `tofu plan` and check that the result matches reality.

Not yet tested end to end. Test it once on a non-critical module and
update this section.

## Encryption passphrase is lost

The state cannot be decrypted; it cannot be recovered. Rebuild it:

1. Generate a new passphrase and store it in the password manager.
2. Delete the state object `<module>/terraform.tfstate` from the bucket.
3. Add `import` blocks for every resource in the module (see
   [Importing existing resources](../opentofu.md#importing-existing-resources)).
4. `tofu plan` must show only imports. Apply it as a saved plan and remove
   the `import` blocks.
