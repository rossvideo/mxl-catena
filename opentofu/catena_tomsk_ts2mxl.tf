// --- device creation --------------------------------

resource "docker_container" "tomsk_ts2mxl_container" {
  name  = "tomsk_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7255"
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

resource "catena_device" "tomsk_ts2mxl" {
  depends_on = [ docker_container.tomsk_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "Tomsk TS Loop"
  slot         = 0
  address      = "http://host.docker.internal"
  port         = 7255
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path" = "/ts/TSU_1920x1080.ts"
    "/inputs/target_domain"      = "/dev/shm/mxl"
    "/inputs/target_flow"     = "9ba70e57-d330-8756-9acc-000020260129"
                                 
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}