# shellcheck shell=bash
# Load OpenTofu credentials into the current shell.
# Usage: source scripts/opentofu-env.sh
# Values are read without echo and never written to disk.
# Leave a prompt empty to skip that variable.

if ! (return 0 2>/dev/null); then
  echo "This script must be sourced: source scripts/opentofu-env.sh" >&2
  exit 1
fi

_opentofu_env_read() {
  local name="$1" prompt="$2" value
  read -r -s -p "${prompt}: " value
  printf '\n'
  if [ -n "$value" ]; then
    export "${name}=${value}"
  fi
}

_opentofu_env_read AWS_ACCESS_KEY_ID "S3 access key ID (<tenant_id>:<key_id>)"
_opentofu_env_read AWS_SECRET_ACCESS_KEY "S3 secret access key"
_opentofu_env_read TF_VAR_state_passphrase "State encryption passphrase"
_opentofu_env_read GITHUB_TOKEN "GitHub token"

unset -f _opentofu_env_read
