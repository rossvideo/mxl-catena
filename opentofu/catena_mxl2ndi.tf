// --- device creation --------------------------------


resource "docker_container" "mxl2ndicontainer" {
  name  = "mxl2ndi_container"
  image = docker_image.mxl2ndi.name
  command = ["--log_dir", "/app/logs"]
  ports {
    internal = "6254"
    external = "7254"
  }
  dynamic "ports" {
    for_each = local.ndi_ports
    content {
      internal = tonumber(ports.value)
      external = tonumber(ports.value)
    }
  }
  volumes {
    host_path      = "/dev/shm/mxl"
    container_path = "/dev/shm/mxl"
  }
  volumes {
    host_path      = "${var.workspace_dir}/external"
    container_path = "/external"
  }
}

locals {
  mxl_inputs = [
    catena_device.ross_ts2mxl,
    catena_device.uk_freeview_ts2mxl,
    catena_device.nature_ts2mxl,
    catena_device.nature3_ts2mxl,
    catena_device.nature2_ts2mxl,
    catena_device.tomsk_ts2mxl
  ]

  mxl_params = merge(
    {
      "/selected_flow_id" = catena_device.ross_ts2mxl.params_map["/inputs/target_flow"]
    },
    merge(concat([
      {
      "/inputs/${length(local.mxl_inputs)}/name"    = "MV Output"
      "/inputs/${length(local.mxl_inputs)}/domain"  = "/dev/shm/mxl"
      "/inputs/${length(local.mxl_inputs)}/flow_id" = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
    }
    ],[
      for idx, dev in local.mxl_inputs : {
        "/inputs/${idx}/name"    = dev.name
        "/inputs/${idx}/domain"  = "/dev/shm/mxl"
        "/inputs/${idx}/flow_id" = dev.params_map["/inputs/target_flow"]
      }
    ])... )
  )
}
// --- device configuration ---------------------------
resource "catena_device" "mxl2ndi" {
  depends_on = [ docker_container.mxl2ndicontainer, 
                 catena_device.ross_ts2mxl,
                 catena_device.uk_freeview_ts2mxl,
                 catena_device.nature_ts2mxl,
                 catena_device.nature3_ts2mxl,
                 catena_device.nature2_ts2mxl,
                 catena_device.tomsk_ts2mxl
 ]
  device_type  = "remote-grpc"
  name         = "Catena MXL to NDI Sink"
  slot         = 0
  address      = "http://host.docker.internal"
  port         = 7254
  
  apply_all = false
  // for each catena_device above, map its target_flow to an input

  params_map = local.mxl_params

  start_command = "/start"
  stop_command  = "/stop"

  device_status {
    oid         = "/status"
    ready_value = "Running"
  }
}