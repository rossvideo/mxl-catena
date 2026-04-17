# # SSG stuff
# resource "docker_image" "ssg" {
#   name        = "srvottdockreg02.rossvideo.com:18445/uma/media-plane:x86_64-u24.04-c12.8-g1.26.10-r1.2.9-0.5.5"
#   keep_locally = true
# }
# resource "docker_tag" "ssg" {
#     source_image = docker_image.ssg.name
#     target_image = "media-plane:latest"
  
# }
resource "docker_image" "ssg" {
  name = "media-plane:latest"
  keep_locally = true
}

# SSG = SoftGear Streaming Gateway
resource "docker_container" "ssg" {
  name  = "ssg"
  # image = docker_tag.ssg.target_image
  image = docker_image.ssg.name
  network_mode = "host"
  ipc_mode = "host"
  privileged = true
  env = [
    "SLOT=11"
  ]
  volumes {
    host_path = "${local.MXL_DOMAIN}"
    container_path = "/dev/shm"
    read_only = false
  }
  upload {
    content = jsonencode({
      "ndi" = {
        "networks" = {
          "ips"       = var.target_ip
          "discovery" = ""
        }
      }
    })
    file = "/root/.ndi/ndi-config.v1.json"
  }
  log_opts = {
    "max-file" = "3",
    "max-size" = "10m"
  }
}

resource "docker_image" "ssg_control" {
  name         = "ssg-control:local"
  keep_locally = true
}

resource "docker_container" "ssg_control" {
  depends_on = [docker_container.ssg]
  name       = "ssg_control"
  image      = docker_image.ssg_control.name
  env = [
    "VIRTUAL_HOST=ssg.${var.base_domain}",
    "VIRTUAL_PROTO=grpc",
    "VIRTUAL_PORT=6254",
  ]
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  ports {
    internal = "6254"
    external = "7246"
  }
  log_opts = {
    "max-file" = "3",
    "max-size" = "10m"
  }
}

resource "catena_device" "ssg" {
  depends_on  = [docker_container.ssg_control]
  device_type = "remote-grpc"
  name        = "SSG Control"
  slot        = 0
  address     = local.catena_endpoint
  port        = 7246

  apply_all = false
  params_map = {
    "/ssg_url"     = "${var.target_ip}:8839"
    "/ssg_mode"    = 1 # 1 = SRT to MXL, 0 = NDI to MXL
    "/ndi_url"     = "${var.target_ip}:5961"
    "/source_name" = "ssg_to_mxl"
    "/srt_url"     = "srt://10.62.122.98:9006"
    "/srt_mode"    = "caller"
    "/mxl_domain"  = "/dev/shm"
    "/mxl_flow_id" = local.SSG_UUID
  }

  device_status {
    oid         = "/source_name"
    ready_value = "ssg_to_mxl"
  }

  start_command = "/start_ssg"
}
