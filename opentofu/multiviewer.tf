// --- device creation --------------------------------
locals {
    INPUTS=[
        {
            name = "nature_ts2mxl"
            label = "Nature dandylion"
            uuid = "24328f33-d330-c9ec-83c5-000020260129"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15000"
            port2 = "15100"
        },
        {
            name = "nature2_ts2mxl"
            label = "Nature river"
            uuid = "a42c729c-d330-efc4-9c11-000020260129"
            # auuid = "69452270-0b81-425b-94e1-c439cbaf1832"
            auuid = ""
            port = "15001"
            port2 = "15101"
        },
        {
            name = "nature3_ts2mxl"
            label = "Nature bird"
            uuid = "896729f3-d330-73cf-1a5c-000020260129"
            # auuid = "528fc92a-461b-426b-a130-15213ca95fae"
            auuid = ""
            port = "15002"
            port2 = "15102"
        },
        {
            name = "mxl_input4"
            label = "MXL Out"
            uuid = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15003"
            port2 = "15103"
        },

        {
            name = "ross_ts2mxl"
            label = "Ross Logo"
            uuid = "025aebb9-d330-f84d-a2cd-000020260129"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15004"
            port2 = "15104"
        },
        {
            name = "tomsk_ts2mxl"
            label = "Tomsk University"
            uuid = "9ba70e57-d330-8756-9acc-000020260129"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15005"
            port2 = "15105"
        },
        {
            name = "uk_freeview_ts2mxl"
            label = "Cartoon from UK Freeview"
            uuid = "c3c715d3-d330-7fdd-baa5-000020260129"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15006"
            port2 = "15106"
        },
        {
            name = "mxl_input8"
            label = "MXL Out2"
            uuid = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15007"
            port2 = "15107"
        },

        {
            name = "mxl_input9"
            label = "Gradient3"
            uuid = "704d0193-b074-448e-af16-f14484c64dbf"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15008"
            port2 = "15108"
        },
        {
            name = "mxl_input10"
            label = "Ball3"
            uuid = "6ab164b9-9de1-44e3-be34-a4b7595d08d9"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15009"
            port2 = "15109"
        },
        {
            name = "mxl_input11"
            label = "SMPTE3"
            uuid = "88c0b9ba-226d-4533-967e-1be89c516e5d"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15010"
            port2 = "15110"
        },
        {
            name = "mxl_input12"
            label = "MXL Out3"
            uuid = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
            # auuid = "fba2bbad-43e6-4b04-8f0c-f586e2c312af"
            auuid = ""
            port = "15011"
            port2 = "15111"
        },

        {
            name = "mxl_input13"
            label = "Gradient4"
            uuid = "704d0193-b074-448e-af16-f14484c64dbf"
            auuid = ""
            port = "15012"
            port2 = "15112"
        },
        {
            name = "mxl_input14"
            label = "Ball4"
            uuid = "6ab164b9-9de1-44e3-be34-a4b7595d08d9"
            auuid = ""
            port = "15013"
            port2 = "15113"
        },
        {
            name = "mxl_input15"
            label = "SMPTE4"
            uuid = "88c0b9ba-226d-4533-967e-1be89c516e5d"
            auuid = ""
            port = "15014"
            port2 = "15114"
        },
        {
            name = "mxl_input16"
            label = "MXL Out4"
            uuid = "3f9618cb-ff4c-49d9-8360-252fd6111d72"
            auuid = ""
            port = "15015"
            port2 = "15115"
        }
    ]
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
        port2 = "19001"
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
    TOOLS_INPUTS=[
        {
            name = "gst-to-mxl-gradient"
            pattern = "gradient"
            wave = "ticks"
            uuid = local.INPUTS[0].uuid
            auuid = local.INPUTS[0].auuid
            width = local.CONTROL.XRES
            height = local.CONTROL.YRES
        },
        {
            name = "gst-to-mxl-ball"
            pattern = "ball"
            wave = "sine"
            uuid = local.INPUTS[1].uuid
            auuid = local.INPUTS[1].auuid
            width = local.CONTROL.XRES
            height = local.CONTROL.YRES
        },
        {
            name = "gst-to-mxl-smpte"
            pattern = "smpte"
            wave = "white-noise"
            uuid = local.INPUTS[2].uuid
            auuid = local.INPUTS[2].auuid
            width = local.CONTROL.XRES
            height = local.CONTROL.YRES
        }]
    TOOLS_OUTPUTS=[
        {
            name = "mxl-to-gst"
            uuid = local.OUTPUTS.uuid
        },
    ]
}
//Inputs
resource "docker_container" "input_containers" {
    for_each = { for input in local.INPUTS : input.name => input }
    name  = each.value.name
    image = docker_image.mxl_input.name
    command = concat(["/app/mxlInput", "${local.MXL_DOMAIN}", each.value.port, each.value.port2, "--uuid", each.value.uuid], try(length(trimspace(each.value.auuid)), 0) > 0 ? ["--auuid", each.value.auuid] : [])

    volumes {
        host_path      = "${local.MXL_DOMAIN}"
        container_path = "${local.MXL_DOMAIN}"
    }
    networks_advanced {
        name = docker_network.multiviewer_network.name
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
    }
  
}
//Multiviewer
resource "docker_container" "multiviewer" {
    name  = "multiviewer"
    image = docker_image.multiviewer.name
    command = ["./multiviewer", "19000", "19100"]
    networks_advanced {
        name = docker_network.multiviewer_network.name
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
            input.name,
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
        "DEFAULT_LAYOUT=e_MVLayout_4x4",
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