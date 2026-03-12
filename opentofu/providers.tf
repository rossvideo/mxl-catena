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
      source  = "opentofu/grafana"
      version = "4.28.0"
    }

    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.7.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
  }
}

# https://search.opentofu.org/provider/kreuzwerker/docker/latest
# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }
provider "docker" {
  host = "ssh://ansible@${var.target_ip}"
  ssh_opts = [
    "-i", "~/.ssh/id_ed25519", "-o", "StrictHostKeyChecking accept-new"
  ]
}

# this is made localy for now
provider "catena" {
  endpoint        = "http://${var.target_ip}"
  transport       = "grpc"
  executables_dir = "exe/"
}
# https://search.opentofu.org/provider/opentofu/grafana/latest
provider "grafana" {
  url  = "http://${var.target_ip}:3000"
  auth = "admin:admin"
}

# https://search.opentofu.org/provider/keycloak/keycloak/latest
provider "keycloak" {
  client_id     = "admin-cli"
  username      = "admin"
  password      = "admin"
  url           = "http://${var.target_ip}:8080"
  initial_login = false
}

# https://search.opentofu.org/provider/cyrilgdn/postgresql/latest
provider "postgresql" {
  host             = "${var.target_ip}"
  port             = 5432
  database         = "platform_manager"
  username         = "postgres"
  password         = "postgres"
  connect_timeout  = 15
  sslmode          = "disable"
  expected_version = "15"
}