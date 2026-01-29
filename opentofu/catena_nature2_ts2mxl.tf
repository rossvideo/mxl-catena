// --- device creation --------------------------------

resource "docker_container" "nature2_ts2mxl_container" {
  name  = "nature2_ts2mxl_container"
  image = docker_image.ts2mxl.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7252"
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

resource "catena_device" "nature2_ts2mxl" {
  depends_on = [ docker_container.nature2_ts2mxl_container ]
  device_type  = "remote-grpc"
  name         = "Nature river TS Loop"
  slot         = 0
  address      = "http://host.docker.internal"
  port         = 7252
  
  apply_all = false
  params_map = {
    "/inputs/ts_file_path" = "/ts/0224_comp.ts"
    "/inputs/target_domain"      = "/dev/shm/mxl"
    "/inputs/target_flow"     = "a42c729c-d330-efc4-9c11-000020260129"
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}