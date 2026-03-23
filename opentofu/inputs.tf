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