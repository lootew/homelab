variable "state_passphrase" {
  description = "Passphrase for client-side state and plan encryption. Set via TF_VAR_state_passphrase."
  type        = string
  sensitive   = true
}
