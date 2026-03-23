
resource "docker_image" "valkey" {
  name = "valkey/valkey:8.0.1-alpine"
  keep_locally = true
}

resource "docker_container" "valkey_local" {
  name  = "catena-valkey-local"
  image = docker_image.valkey.name

  ports {
    internal = 6379
    external = 6379
  }

  command = ["valkey-server", 
    "--appendonly", "yes", 
    "--maxmemory", "256mb", 
    "--maxmemory-policy", "allkeys-lru"]

  restart = "unless-stopped"

  healthcheck {
    test     = ["CMD", "valkey-cli", "ping"]
    interval = "10s"
    timeout  = "3s"
    retries  = 3
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}


resource "docker_image" "catena-mcp" {
  name = "deploy-catena-mcp-local:latest"
  keep_locally = true
}

resource "docker_container" "catena_mcp_local" {
  depends_on = [docker_container.valkey_local]
  
  name  = "catena-mcp-server-local"
  image = docker_image.catena-mcp.name

  ports {
    internal = 8888
    external = 8888
  }

  env = toset([
    # Grab the openai key from the environment variable
    "OPENAI_API_KEY=${var.openai_api_key}",
    "CATENA_USE_MOCK=false",
    # "CATENA_CATENA_ENDPOINT=${var.target_ip}:${catena_device.mxl2ndi.port}",
    "CATENA_CATENA_ENDPOINT=${var.target_ip}:7254",
    "CATENA_ENABLE_FALLBACK=true",

    "CATENA_GRPC_PORT=50051",
    "CATENA_HTTP_PORT=8888",

    "CATENA_VALKEY_ENABLED=true",
    "CATENA_VALKEY_ADDR=${var.target_ip}:${docker_container.valkey_local.ports[0].external}",

    "CATENA_API_TOKEN=33b6badab79df1f18e76d1b1c147b80276414b2a7b2900a5c28ba42a7b37824a",
    "CATENA_AUTH_ENABLED=false", # set true once you have tls
    "CATENA_AUTH_USERNAME=admin",
    # CatenaMCP@RRL
    "CATENA_AUTH_PASSWORD_HASH=$2a$10$01VOVzgiaOvRlcEJhnwovOXenSEThuz6OSyAh5GNUQnmHoPcN7ao6",
    "CATENA_INFLUX_ENABLED=false"
    

  ])
  networks_advanced {
    name    = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
  restart = "unless-stopped"

}