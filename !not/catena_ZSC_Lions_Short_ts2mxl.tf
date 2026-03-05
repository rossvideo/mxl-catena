// --- device creation --------------------------------

resource "docker_container" "zsc_lions_short_ts2mxl_container" {
  name  = "zsc_lions_short_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7253"
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

resource "catena_device" "zsc_lions_short_ts2mxl" {
  depends_on = [ docker_container.zsc_lions_short_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "ZSC Lions Short"
  slot         = 0
  address      = "${local.catena_endpoint}"
  port         = 7253
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path"  = "/ts/ZSC_Lions_Short.ts"
    "/inputs/target_domain" = "${local.MXL_DOMAIN}"
    "/inputs/target_flow"   = "896729f3-d330-73cf-1a5c-000020260129"                       
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}