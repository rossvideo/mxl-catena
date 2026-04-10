// --- device creation --------------------------------
resource "docker_container" "ts2mxl_containers" {
  for_each = { for input in local.CATENA_INPUTS : input.container_name => input }
  name     = each.value.container_name
  image    = docker_image.ts2mxl.name
  ports {
    internal = "6254"
    external = each.value.external_port
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
    aliases = [each.value.container_name]
  }
  env = [
    "VIRTUAL_HOST=${each.value.container_name}.${var.base_domain}",
    "VIRTUAL_PROTO=grpc",
    "VIRTUAL_PORT=6254",
  ]
  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = local.MXL_DOMAIN
    read_only      = false
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/ts"
    container_path = "/ts"
    read_only      = false
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}

// --- device configuration ---------------------------

resource "catena_device" "ts2mxl" {
  depends_on  = [docker_container.ts2mxl_containers]
  for_each    = { for input in local.CATENA_INPUTS : input.container_name => input }
  device_type = "remote-grpc"
  name        = each.value.label
  slot        = 0
  address     = local.catena_endpoint
  port        = each.value.external_port

  apply_all = false
  params_map = {
    "/inputs/ts_file_path"  = each.value.ts_file_path
    "/inputs/target_domain" = "${local.MXL_DOMAIN}"
    "/inputs/target_flow"   = each.value.uuid
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}