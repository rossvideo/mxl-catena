terraform {
  required_providers {
    catena = {
      source  = "local/catena"
      version = "0.1.0"
    }
    docker = {
      # https://search.opentofu.org/provider/calxus/docker/latest
      source = "calxus/docker"
      version = "3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "catena" {
  endpoint  = "localhost"
  transport = "grpc"
  executables_dir = "exe/"
}
