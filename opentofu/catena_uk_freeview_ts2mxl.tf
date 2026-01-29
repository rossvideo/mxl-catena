// --- device creation --------------------------------

resource "docker_container" "uk_freeview_ts2mxl_container" {
  name  = "uk_freeview_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7249"
  }
  volumes {
    host_path      = "/dev/shm/mxl"
    container_path = "/dev/shm/mxl"
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/ts/586000000.ts"
    container_path = "/ts/586000000.ts"
  }
}

// --- device configuration ---------------------------

resource "catena_device" "uk_freeview_ts2mxl" {
  depends_on = [ docker_container.uk_freeview_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "UK Freeview"
  slot         = 0
  address      = "http://host.docker.internal"
  port         = 7249
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path"        = "/ts/586000000.ts"
    "/inputs/target_domain"      = "/dev/shm/mxl"
    "/inputs/target_flow"     = "c3c715d3-d330-7fdd-baa5-000020260129"
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}