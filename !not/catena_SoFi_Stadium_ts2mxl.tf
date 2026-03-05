// --- device creation --------------------------------

resource "docker_container" "sofi_stadium_ts2mxl_container" {
  name  = "sofi_stadium_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7252"
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

resource "catena_device" "sofi_stadium_ts2mxl" {
  depends_on = [ docker_container.sofi_stadium_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "SoFi Stadium"
  slot         = 0
  address      = "${local.catena_endpoint}"
  port         = 7252
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path"  = "/ts/SoFi_Stadium.ts"
    "/inputs/target_domain" = "${local.MXL_DOMAIN}"
    "/inputs/target_flow"   = "a42c729c-d330-efc4-9c11-000020260129"                       
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}