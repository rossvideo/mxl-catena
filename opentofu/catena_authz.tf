resource "docker_container" "catena_authz" {
  name  = "catena_authz"
  image = "ghcr.io/rossvideo/catena:one-of-everything-grpc-dev"
  log_opts = {
    "max-file" = "3",
    "max-size" = "10m"
  }

  networks_advanced {
    name    = docker_network.multiviewer_network.name
    aliases = ["catena_authz"]
  }

  env = [
    "VIRTUAL_HOST=authz.${var.base_domain}",
    "VIRTUAL_PROTO=grpc",
    "VIRTUAL_PORT=6254",

    "CATENA_AUTHZ=yes",
  ]
}