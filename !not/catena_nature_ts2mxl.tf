// --- device creation --------------------------------

resource "docker_container" "nature_ts2mxl_container" {
  name  = "nature_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7251"
  }
  volumes {
    host_path      = "${local.MXL_DOMAIN}"
    container_path = "${local.MXL_DOMAIN}"
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/ts"
    container_path = "/ts"
  }
}

// --- device configuration ---------------------------

resource "catena_device" "nature_ts2mxl" {
  depends_on = [ docker_container.nature_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "Nature dandylion"
  slot         = 0
  address      = "${local.catena_endpoint}"
  port         = 7251
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path" = "/ts/0131_comp.ts"
    "/inputs/target_domain"      = "${local.MXL_DOMAIN}"
    "/inputs/target_flow"     = "24328f33-d330-c9ec-83c5-000020260129"
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}