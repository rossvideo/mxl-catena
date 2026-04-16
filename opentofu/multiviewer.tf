// --- Multiviewer creation --------------------------------
locals {
    INPUTS = concat(
    [
      {
        name = "ndi2mxl"
        label = "NDI to MXL"
        uuid = "19736e97-a32d-40b3-a2b1-4aa0cf4a5f10"
        auuid = ""
        port = "15000"
        port2 = "15100"
      },
      {
        name  = "engine"
        label = "MediaIO"
        uuid  = "977c03f8-4423-4f29-8726-40d4798f85a4"
        auuid = ""
        port  = "15001"
        port2 = "15101"
      },
      {
        name  = "ssg"
        label = "SSG Output"
        uuid  = "550e8400-e29b-41d4-a716-446655440000"
        auuid = ""
        port  = "15002"
        port2 = "15102"
      },
      {
        name  = local.OUTPUTS.name
        label = local.OUTPUTS.label
        uuid  = local.OUTPUTS.uuid
        # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
        auuid = ""
        port  = "15003"
        port2 = "15103"
      }
    ],
    [for idx, dev in local.CATENA_INPUTS : {
      name  = dev.container_name
      label = dev.label
      uuid  = dev.uuid
      auuid = ""
      port  = tostring(15004 + idx)
      port2 = tostring(15104 + idx)
  }]
  )
  OUTPUTS = {
    name  = "mxl_output"
    label = "Output"
    uuid  = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
    port  = "16000"
    port2 = "16100"
  }
  MULTIVIEWER = {
    name  = "multiviewer"
    port  = "19000"
    port2 = "19100"
  }
  CONTROL = {
    name            = "control"
    BACKLOG         = "1"
    XRES            = "1920"
    YRES            = "1080"
    RATE_NUM        = "24000"
    RATE_DEN        = "1001"
    metric_port     = "14100"
    MXL_TO_GST_PORT = "50000"
  }
  TOOLS_OUTPUTS = [
    {
      name = "mxl-to-gst"
      uuid = local.OUTPUTS.uuid
    },
  ]
}
//Inputs
resource "docker_container" "input_containers" {
  for_each = {
    for idx, input in local.INPUTS :
    input.name => merge(input, { index = idx })
  }

  name  = "${each.value.name}_input"
  image = docker_image.mxl_input.name

  command = concat(
    ["/app/mxlInput", each.value.port, each.value.port2,"-d",  "${local.MXL_DOMAIN}", "-v", each.value.uuid],
    try(length(trimspace(each.value.auuid)), 0) > 0 ? ["-a", each.value.auuid] : []
  )

  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = local.MXL_DOMAIN
    read_only      = false
  }

  networks_advanced {
    name    = docker_network.multiviewer_network.name
    aliases = ["input${each.value.index + 1}"]
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}
//Outputs
resource "docker_container" "output_containers" {
  name    = local.OUTPUTS.name
  image   = docker_image.mxl_output.name
  command = ["/app/mxlOutput",local.OUTPUTS.port, local.OUTPUTS.port2,"-d",  "${local.MXL_DOMAIN}", "-v", local.OUTPUTS.uuid]

  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = local.MXL_DOMAIN
    read_only      = false
  }
  networks_advanced {
    name    = docker_network.multiviewer_network.name
    aliases = ["output"]
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }

}
//Multiviewer
resource "docker_container" "multiviewer" {
  name    = "multiviewer"
  image   = docker_image.multiviewer.name
  command = ["./multiviewer", "${local.MULTIVIEWER.port}", "${local.MULTIVIEWER.port2}"]
  networks_advanced {
    name    = docker_network.multiviewer_network.name
    aliases = ["multiviewer"]
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}

//Control
resource "docker_container" "control" {
  depends_on = [docker_container.input_containers, docker_container.multiviewer, docker_container.output_containers]
  name       = "control"
  image      = docker_image.control.name
  command = concat(
    ["./control"],
    flatten([
      for idx, input in local.INPUTS : [
        "mxl",
        "Input ${idx + 1}",
        "${input.name}_input",
        tostring(input.port),
      ]
    ]),
    ["/o", "Output", local.OUTPUTS.name, local.OUTPUTS.port, local.OUTPUTS.port + 1],
    ["/p"],
    ["/m", "multiviewer", local.MULTIVIEWER.port, local.MULTIVIEWER.port + 1],
    ["/e", local.CONTROL.BACKLOG, local.CONTROL.XRES, local.CONTROL.YRES, local.CONTROL.RATE_NUM, local.CONTROL.RATE_DEN],
    ["bgra"],
    [local.CONTROL.metric_port]
  )

  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }

}
//cheetah-lite
resource "docker_container" "cheetah_lite" {
  depends_on = [docker_container.control]
  name       = "cheetah-lite"
  image      = docker_image.cheetah_lite.name
  command    = ["/app/cheetah-lite"]
  ports {
    internal = "6789"
    external = "6789"
  }
  env = toset(concat(
    [
      "VPE_ADDRESS=${docker_container.control.name}:8030",
      "WS_BIND_ADDRESS=0.0.0.0:6789",
    ],
    [
      for idx, input in local.INPUTS :
      "SOURCE${idx + 1}_LABEL=${input.label}"
    ],
    [
      "MAX_SOURCE_ID=${length(local.INPUTS)}",
      "DEFAULT_LAYOUT=e_MVLayout_2_4_4_Hor"
      # "DEFAULT_LAYOUT=e_MVLayout_2_4",
    ]
  ))
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}

# MediaMTX
resource "docker_image" "mediamtx" {
  name="bluenviron/mediamtx:1.17.0"
  keep_locally = true
}

locals {
  mediamtx_host = "stream.${var.base_domain}"
}

resource "docker_container" "mediamtx" {
  name  = "mediamtx"
  image = docker_image.mediamtx.name
  env = [
    "MTX_WEBRTCADDITIONALHOSTS=${var.target_ip}",
    "MTX_WEBRTCICESERVERS2=[]",
    "MTX_WEBRTCLOCALTCPADDRESS=:8189",
    "MTX_HLS=no",

    "VIRTUAL_HOST=${local.mediamtx_host}",
    "VIRTUAL_PORT=8889",
  ]
  ports {
    internal = "8554"
    external = "8554"
  }
  ports {
    internal = "8889"
    external = "8889"
  }
  ports {
    internal = "8189"
    external = "8189"
    protocol = "udp"
  }
  ports {
    internal = "8189"
    external = "8189"
    protocol = "tcp"
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}


# mxlToGst
resource "docker_container" "tools_outputs" {
  depends_on = [docker_container.output_containers, docker_container.mediamtx]
  for_each   = { for tool in local.TOOLS_OUTPUTS : tool.name => tool }
  name       = each.value.name
  image      = docker_image.mxl_tools.name
  command = concat(["/app/mxlToGst",
    "-d", "${local.MXL_DOMAIN}",
    "-v", each.value.uuid,
    # "-g", "!  video/x-raw,format=I420 ! svtav1enc preset=10 cqp=36 parameters-string=tile-rows=1:tile-columns=2 ! av1parse ! rtspclientsink location=rtsp://localhost:8554/mxl-mv-demo protocols=tcp"
    "-g", "!video/x-raw,format=I420 ! x264enc tune=zerolatency speed-preset=ultrafast key-int-max=60 bframes=0 ! h264parse config-interval=1 ! rtspclientsink location=rtsp://localhost:8554/mxl-mv-demo protocols=tcp"
  ])
  # ports {
  #   internal = local.CONTROL.MXL_TO_GST_PORT
  #   external = local.CONTROL.MXL_TO_GST_PORT
  # }
  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = local.MXL_DOMAIN
    read_only      = false
  }
  network_mode = "host"
  # networks_advanced {
  #   name = docker_network.multiviewer_network.name
  # }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}

# wait 5 seconds then restart tools_outputs
resource "null_resource" "restart_tools_outputs" {
  depends_on = [docker_container.tools_outputs]
  connection {
    type     = "ssh"
    user     = var.target_user
    private_key = file(var.ssh_private_key_path)
    host     = var.target_ip
  }
  provisioner "remote-exec" {
    inline =["sleep 5",
    "sleep 5 && docker restart ${join(" ", [for c in docker_container.tools_outputs : c.name])}"]
  }
}

resource docker_container "cheetah_catena" {
  name  = "cheetah-catena"
  image = docker_image.cheetah_catena.name
  ports {
    internal = "6254"
    external = "7247"
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  env = [
    # this one's defaulting to a weird port for some reason
    "CATENA_PORT=6254",

    "VIRTUAL_HOST=cheetah.${var.base_domain}",
    "VIRTUAL_PROTO=grpc",
    "VIRTUAL_PORT=6254",
  ]
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}

resource "catena_device" "cheetah" {
  depends_on = [ docker_container.cheetah_catena ]
  device_type = "remote-grpc"
  name        = "Cheetah Catena Control"
  slot        = 0
  address     = local.catena_endpoint
  port        = docker_container.cheetah_catena.ports[0].external

  apply_all = false
  params_map = {
    "/websocket_url" = "${var.target_ip}:${docker_container.cheetah_lite.ports[0].external}"
  }

  start_command = "/open_websocket"
  stop_command  = "/close_websocket"

  device_status {
    oid         = "/status"
    ready_value = "1"
  }
}
