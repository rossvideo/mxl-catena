// --- device creation --------------------------------


resource "docker_container" "ndi2mxl_container" {
  name     = "ndi2mxl_container"
  image    = docker_image.ndi2mxl.name
  command  = ["--log_dir", "/app/logs"]
  network_mode = "host"
  env = [
    "CATENA_PORT=7260"
  ]
  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = local.MXL_DOMAIN
    read_only      = false
  }
  volumes {
    host_path      = "${var.workspace_dir}/external"
    container_path = "/external"
    read_only      = false
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}

// --- device configuration ---------------------------
resource "catena_device" "ndi2mxl" {
  depends_on = [
    catena_device.ts2mxl,
    docker_container.multiviewer,
    docker_container.ndi2mxl_container,
  ]
  device_type = "remote-grpc"
  name        = "Catena NDI to MXL Sink"
  slot        = 0
  address     = local.catena_endpoint
  port        = 7260

  apply_all = false
  // for each catena_device above, map its target_flow to an input

  params_map = {
    # "/ndi_source_ips" = "10.62.152.123"
    "/ndi_source_ips" = "10.62.215.203,10.62.215.210,10.62.215.213,10.62.215.211"
  }

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}