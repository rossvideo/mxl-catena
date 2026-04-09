# SSG stuff
resource "docker_image" "ssg" {
  name        = "srvottdockreg02.rossvideo.com:18445/uma/media-plane:x86_64-u24.04-c12.8-g1.26.10-r1.2.9-0.5.5"
  keep_locally = true
}
resource "docker_tag" "ssg" {
    source_image = docker_image.ssg.name
    target_image = "media-plane:latest"
  
}
resource "docker_container" "ssg" {
  name  = "ssg"
  image = docker_tag.ssg.target_image
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
  volumes {
    host_path      = "${var.workspace_dir}/external/ndi"
    container_path = "/root/.ndi"
    read_only      = false
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}
locals {
  pipeline_json=<<EOT
{
  "version": "1.0", 
  "name": "examplsdsde_srt_to_srt", 
  "source": [
  {
    "name": "SRT Input", 
    "protocol": "SRT", 
    "srtSettings": {
      "srtUrl": "srt://:9000", 
      "mode": "listener", 
      "latency": 200}
  }], 
  "dest": [
  {
    "name": "Output 1", 
    "protocol": "SRT", 
    "srtSettings": {
      "srtUrl": "srt://:9998", 
      "mode": "listener", 
      "latency": 200}
  }], 
  "process": null
}
EOT
}
resource "null_resource" "ssg_curling" {
  depends_on = [docker_container.ssg]
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
    inline =[ "sleep 5",
      "curl -X PUT 'http://localhost:8839/api/v1/licenses?activation=https://activation.rossvideo.com&productkeys=FT9DK-3VW26-C3YRN'",
      "curl -X POST 'http://localhost:8839/api/v1/pipeline' --data '${local.pipeline_json}' -H 'Content-Type: application/json'",
      "curl -X POST 'http://localhost:8839/pipelines/examplsdsde_srt_to_srt/state?name=playing'"]
  }  
}