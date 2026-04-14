resource "docker_container" "nginx_proxy" {
  name  = "nginx_proxy"
  image = "jwilder/nginx-proxy:latest"
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  ports {
    internal = 443
    external = 443
  }
  log_opts = {
    "max-file" = "3",
    "max-size" = "10m"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/tmp/docker.sock"
    read_only      = true
  }

  volumes {
    host_path      = "${var.workspace_dir}/certs/letsencrypt/live/${var.base_domain}/fullchain.pem"
    container_path = "/etc/nginx/certs/${var.base_domain}.crt"
    read_only      = true
  }

  volumes {
    host_path      = "${var.workspace_dir}/certs/letsencrypt/live/${var.base_domain}/privkey.pem"
    container_path = "/etc/nginx/certs/${var.base_domain}.key"
    read_only      = true
  }

  upload {
    content = "location = / {\n    return 302 /mxl-mv-demo/;\n}\n"
    file    = "/etc/nginx/vhost.d/${local.mediamtx_host}"
  }
}