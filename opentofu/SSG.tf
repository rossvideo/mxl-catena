# # SSG stuff
# resource "docker_image" "ssg" {
#   name        = "srvottdockreg02.rossvideo.com:18445/uma/media-plane:x86_64-u24.04-c12.8-g1.26.10-r1.2.9-0.5.5"
#   keep_locally = true
# }
# resource "docker_tag" "ssg" {
#     source_image = docker_image.ssg.name
#     target_image = "media-plane:latest"
  
# }
resource "docker_image" "ssg" {
  name = "media-plane:latest"
  keep_locally = true
}

# SSG = SoftGear Streaming Gateway
resource "docker_container" "ssg" {
  name  = "ssg"
  # image = docker_tag.ssg.target_image
  image = docker_image.ssg.name
  network_mode = "host"
  ipc_mode = "host"
  privileged = true
  env = [
    "SLOT=11"
  ]
  volumes {
    host_path = "${local.MXL_DOMAIN}"
    container_path = "/dev/shm"
    read_only = false
  }
  upload {
    content = jsonencode({
      "ndi" = {
        "networks" = {
          "ips"       = "10.62.152.123"
          "discovery" = ""
        }
      }
    })
    file = "/root/.ndi/ndi-config.v1.json"
  }
  log_opts = {
    "max-file" = "3",
    "max-size" = "10m"
  }
}

locals {
  pipeline_json = jsonencode({
    "version": "1.0",
    "name": "srt_to_mxl",
    "source": [{
      "name": "srt_to_mxl",
      "protocol": "SRT",
      "srtSettings": {
        # "srtUrl": "srt://10.62.122.221:9000",
        "srtUrl": "srt://10.62.122.98:9006",
        "mode": "caller",
        "latency": 200
      },
      "video": [{ "name": "srt_to_mxl_video" }],
      "audio": []
    }],
    "dest": [{
      "protocol": "MXL",
      "mxlSettings": {
        "domain": "/dev/shm",
        "flowId": "${local.SSG_UUID}",
        "authorityPort": 5000
      },
      "video": [{ "inputs": { "sourceName": "srt_to_mxl_video" } }]
    }]
  })
}
# locals {
#   pipeline_json=<<EOT
# {
#   "version": "1.0",
#   "name": "example_ndi_to_mxl",
#   "source": [
#     {
#       "name": "NDI Source",
#       "protocol": "NDI",
#       "url": "10.62.152.123:5961",
#       "video": [
#         {
#           "name": "example_ndi_to_mxl_video"
#         }
#       ],
#       "audio": [
#         {
#           "name": "example_ndi_to_mxl_audio"
#         }
#       ]
#     }
#   ],
#   "dest": [
#     {
#       "protocol": "MXL",
#       "mxlSettings": {
#         "domain": "/dev/shm",
#         "flowId": "550e8400-e29b-41d4-a716-446655440000",
#         "authorityPort": 5000
#       },
#       "video": [
#         {
#           "inputs": {
#             "sourceName": "example_ndi_to_mxl_video"
#           }
#         }
#       ]
#     }
#   ],
#   "process": null
# }
# EOT
# }
resource "null_resource" "ssg_curling" {
  depends_on = [docker_container.ssg, catena_device.mxl2ndi]
  triggers = {
    always_run = timestamp()
  }
  connection {
    type     = "ssh"
    user     = var.target_user
    private_key = file(var.ssh_private_key_path)
    host     = var.target_ip
  }
  provisioner "remote-exec" {
    inline =[ "sleep 10",
      "curl -X PUT 'http://localhost:8839/api/v1/licenses?activation=https://activation.rossvideo.com&productkeys=FT9DK-3VW26-C3YRN'",
      "curl -X POST 'http://localhost:8839/api/v1/pipeline' --data '${local.pipeline_json}' -H 'Content-Type: application/json'",
      "curl -X PUT 'http://localhost:8839/pipelines/srt_to_mxl/state?name=playing'"]
  }  
}