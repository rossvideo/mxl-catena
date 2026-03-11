locals {
  target_ip = "10.62.152.123"
}

terraform {
  required_providers {
    catena = {
      source  = "local/catena"
      version = "0.1.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.9.0"
    }

    grafana = {
      source = "opentofu/grafana"
      version = "4.27.0"
    }

    keycloak = {
      source = "keycloak/keycloak"
      version = "5.7.0"
    }
    
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# https://search.opentofu.org/provider/kreuzwerker/docker/latest
# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }
provider "docker" {
  host     = "ssh://ansible@${local.target_ip}"
  ssh_opts = [
    "-i", "~/.ssh/id_ed25519", "-o", "StrictHostKeyChecking accept-new"
  ]
}

# this is made localy for now
provider "catena" {
  endpoint  = "${local.target_ip}"
  transport = "grpc"
  executables_dir = "exe/"
}
# https://search.opentofu.org/provider/opentofu/grafana/latest
provider "grafana" {
  url  = "http://${local.target_ip}:3000"
  auth = "admin:admin"
}

# https://search.opentofu.org/provider/keycloak/keycloak/latest
provider "keycloak" {
	client_id     = "admin-cli"
	username      = "admin"
	password      = "admin"
	url           = "http://${local.target_ip}:8080"
  initial_login = false
}