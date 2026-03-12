// --- device creation --------------------------------
resource "docker_container" "ts2mxl_containers" {
  for_each = { for input in local.CATENA_INPUTS : input.container_name => input }
  name     = each.value.container_name
  image    = docker_image.ts2mxl.name
  command  = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = each.value.external_port
  }
  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = local.MXL_DOMAIN
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/ts"
    container_path = "/ts"
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