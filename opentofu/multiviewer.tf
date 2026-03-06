// --- Multiviewer creation --------------------------------
locals {
    INPUTS= concat(
            [
                {
                    name = local.OUTPUTS.name
                    label = local.OUTPUTS.label
                    uuid = local.OUTPUTS.uuid
                    # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
                    auuid = ""
                    port = "15000"
                    port2 = "15100"
                }
            ],
            [ for idx, dev in local.CATENA_INPUTS :{
                name = dev.container_name
                label = dev.label
                uuid = dev.uuid
                auuid = ""
                port = tostring(15001 + idx)
                port2 = tostring(15101 + idx)
            }])
        
    
    OUTPUTS={
        name = "mxl_output"
        label = "Output"
        uuid = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
        port = "16000"
        port2 = "16100"
    }
    MULTIVIEWER={
        name = "multiviewer"
        port = "19000"
        port2 = "19100"
    }
    CONTROL={
        name = "control"
        BACKLOG = "1"
        XRES = "1920"
        YRES = "1080"
        RATE_NUM = "60000"
        RATE_DEN = "1000"
        bgra_port = "14100"
        MXL_TO_GST_PORT="50000"
    }
    # TOOLS_INPUTS=[
    #     {
    #         name = "gst-to-mxl-gradient"
    #         pattern = "gradient"
    #         wave = "ticks"
    #         uuid = local.INPUTS[0].uuid
    #         auuid = local.INPUTS[0].auuid
    #         width = local.CONTROL.XRES
    #         height = local.CONTROL.YRES
    #     },
    #     {
    #         name = "gst-to-mxl-ball"
    #         pattern = "ball"
    #         wave = "sine"
    #         uuid = local.INPUTS[1].uuid
    #         auuid = local.INPUTS[1].auuid
    #         width = local.CONTROL.XRES
    #         height = local.CONTROL.YRES
    #     },
    #     {
    #         name = "gst-to-mxl-smpte"
    #         pattern = "smpte"
    #         wave = "white-noise"
    #         uuid = local.INPUTS[2].uuid
    #         auuid = local.INPUTS[2].auuid
    #         width = local.CONTROL.XRES
    #         height = local.CONTROL.YRES
    #     }]
    TOOLS_OUTPUTS=[
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
        ["/app/mxlInput", "${local.MXL_DOMAIN}", each.value.port, each.value.port2, "--uuid", each.value.uuid],
        try(length(trimspace(each.value.auuid)), 0) > 0 ? ["--auuid", each.value.auuid] : []
    )

    volumes {
        host_path      = "${local.MXL_DOMAIN}"
        container_path = "${local.MXL_DOMAIN}"
    }

    networks_advanced {
        name    = docker_network.multiviewer_network.name
        aliases = ["input${each.value.index + 1}"]
    }
}
//Outputs
resource "docker_container" "output_containers" {
    name  = local.OUTPUTS.name
    image = docker_image.mxl_output.name
    command = ["/app/mxlOutput", "${local.MXL_DOMAIN}", local.OUTPUTS.port, local.OUTPUTS.port2, "--uuid", local.OUTPUTS.uuid]

    volumes {
        host_path      = "${local.MXL_DOMAIN}"
        container_path = "${local.MXL_DOMAIN}"
    }
    networks_advanced {
        name = docker_network.multiviewer_network.name
        aliases = ["output"]
    }
  
}
//Multiviewer
resource "docker_container" "multiviewer" {
    name  = "multiviewer"
    image = docker_image.multiviewer.name
    command = ["./multiviewer", "${local.MULTIVIEWER.port}", "${local.MULTIVIEWER.port2}"]
    networks_advanced {
        name = docker_network.multiviewer_network.name
        aliases = ["multiviewer"]
    }
}

//Control
resource "docker_container" "control" {
    depends_on = [docker_container.input_containers]
    name  = "control"
    image = docker_image.control.name
    command = concat(
        ["./control"],
        flatten([
            for idx, input in local.INPUTS : [
            "Input ${idx + 1}",
            "${input.name}_input",
            tostring(input.port),
            ]
        ]),
        ["/o", "Output", local.OUTPUTS.name, local.OUTPUTS.port, local.OUTPUTS.port+1],
        ["/p"],
        ["/m", "multiviewer", local.MULTIVIEWER.port, local.MULTIVIEWER.port+1],
        ["/e", local.CONTROL.BACKLOG, local.CONTROL.XRES, local.CONTROL.YRES, local.CONTROL.RATE_NUM, local.CONTROL.RATE_DEN],
        [ "bgra", local.CONTROL.bgra_port],
    )
    
    networks_advanced {
        name = docker_network.multiviewer_network.name
    }
  
}
//cheetah-lite
resource "docker_container" "cheetah_lite" {
    name  = "cheetah-lite"
    image = docker_image.cheetah_lite.name
    command = ["/app/cheetah-lite"]
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
        "DEFAULT_LAYOUT=e_MVLayout_4_2_4_Ver",
    ]
    ))
    networks_advanced {
        name = docker_network.multiviewer_network.name
    }
  
}

# //Part2
# resource "docker_container" "tools_inputs" {
#     depends_on = [ docker_container.cheetah_lite, docker_container.multiviewer, docker_container.control ]
#     for_each = { for tool in local.TOOLS_INPUTS : tool.name => tool }
#     name  = each.value.name
#     image = docker_image.mxl_tools.name
#     command = concat(["/app/gstToMxl",
#      "--domain", "${local.MXL_DOMAIN}",
#      "--pattern", each.value.pattern, 
#      "--uuid", each.value.uuid, 
#      "--width", each.value.width,
#      "--height", each.value.height, 
#      "--auuid", each.value.auuid,
#      "--wave", each.value.wave])

#     volumes {
#         host_path      = "${local.MXL_DOMAIN}"
#         container_path = "${local.MXL_DOMAIN}"
#     }
#     networks_advanced {
#         name = docker_network.multiviewer_network.name
#     }
# }

resource "docker_container" "tools_outputs" {
    depends_on = [ docker_container.output_containers ]
    for_each = { for tool in local.TOOLS_OUTPUTS : tool.name => tool }
    name  = each.value.name
    image = docker_image.mxl_tools.name
    command = concat(["/app/mxlToGst",
     "--domain", "${local.MXL_DOMAIN}",
     "--uuid", each.value.uuid,
     "--port", local.CONTROL.MXL_TO_GST_PORT])
    ports {
      internal = local.CONTROL.MXL_TO_GST_PORT
      external = local.CONTROL.MXL_TO_GST_PORT
    }
    volumes {
        host_path      = "${local.MXL_DOMAIN}"
        container_path = "${local.MXL_DOMAIN}"
    }
    networks_advanced {
        name = docker_network.multiviewer_network.name
    }
  
}