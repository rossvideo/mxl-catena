// --- device creation --------------------------------

resource "docker_container" "ross_ts2mxl_container" {
  name  = "ross_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7250"
  }
  volumes {
    host_path      = "/dev/shm/mxl"
    container_path = "/dev/shm/mxl"
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/ts"
    container_path = "/ts"
  }
}

// --- device configuration ---------------------------

resource "catena_device" "ross_ts2mxl" {
  depends_on = [ docker_container.ross_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "Ross Logo Loop"
  slot         = 0
  address      = "http://host.docker.internal"
  port         = 7250
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path" = "/ts/ross_logo_loop2.ts"
    "/inputs/target_domain"      = "/dev/shm/mxl"
    "/inputs/target_flow"     = "025aebb9-d330-f84d-a2cd-000020260129"                       
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}