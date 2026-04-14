variable "workspace_dir" {
  type = string
}
variable "target_ip" {
  type = string
}

variable "openai_api_key" {
  type      = string
  sensitive = true
}
variable "target_user" {
  type = string
}
variable "ssh_private_key_path" {
  type = string
}
variable "base_domain" {
  type    = string
}
