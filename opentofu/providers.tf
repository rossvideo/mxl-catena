terraform {
  required_providers {
    catena = {
      source  = "local/catena"
      version = "0.1.0"
    }
    docker = {
      # https://search.opentofu.org/provider/kreuzwerker/docker/latest
      source  = "kreuzwerker/docker"
      version = "3.9.0"
    }
  }
}

# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

provider "docker" {
  host     = "ssh://ansible@10.62.152.123"
  ssh_opts = [
    "-i", "~/.ssh/id_ed25519", "-o", "StrictHostKeyChecking accept-new"
  ]
}


provider "catena" {
  endpoint  = "10.62.152.123"
  transport = "grpc"
  executables_dir = "exe/"
}
