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
    host_path      = "${local.MXL_DOMAIN}"
    container_path = "${local.MXL_DOMAIN}"
  }
  volumes {
    host_path      = "${var.workspace_dir}/external"
    container_path = "/external"
  }
}

locals {
  mxl_params = merge(
    {
      "/selected_flow_id" = local.CATENA_INPUTS[0].uuid
    },
    merge(concat(
    #   [
    #   {
    #   "/inputs/${length(local.mxl_inputs)}/name"    = "MV Output"
    #   "/inputs/${length(local.mxl_inputs)}/domain"  = "${local.MXL_DOMAIN}"
    #   "/inputs/${length(local.mxl_inputs)}/flow_id" = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
    #   }
    # ],
    [
      for idx, dev in local.CATENA_INPUTS : {
        "/inputs/${idx}/name"    = dev.label
        "/inputs/${idx}/domain"  = "${local.MXL_DOMAIN}"
        "/inputs/${idx}/flow_id" = dev.uuid
      }
    ])... )
  )
}
// --- device configuration ---------------------------
resource "catena_device" "mxl2ndi" {
  depends_on = [ catena_device.ts2mxl[0]]
  device_type  = "remote-grpc"
  name         = "Catena MXL to NDI Sink"
  slot         = 0
  address      = "${local.catena_endpoint}"
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