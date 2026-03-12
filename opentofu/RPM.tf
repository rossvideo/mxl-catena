# ------------------------------ Database for RPM ------------------------------
resource "docker_volume" "rpm_database_data" {
  name = "rpm_database_data"
}

resource "docker_container" "rpm_database" {
  name  = "rpm_database"
  image = docker_image.rpm_database.name

  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=password",
    "POSTGRES_DB=platform_manager",
    "POSTGRES_HOST_AUTH_METHOD=trust"
  ]

  command = [
    "postgres",
    "-c",
    "listen_addresses=*"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    volume_name    = docker_volume.rpm_database_data.name
    container_path = "/var/lib/postgresql/data"
  }

  volumes {
    host_path      = "${var.workspace_dir}/external/sql"
    container_path = "/docker-entrypoint-initdb.d"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
}

resource "docker_image" "rpm" {
  name = "rpm:latest"

  build {
    context    = "${var.workspace_dir}/external/rpm"
    dockerfile = "Dockerfile.rpm"
  }
  force_remove = true
}

resource "docker_container" "rpm" {
  depends_on = [docker_container.rpm_database, docker_image.rpm]

  name  = "rpm"
  image = docker_image.rpm.name

  env = toset([
    "DB_HOST=rpm_database",
    "DB_PORT=5432",
    "DB_NAME=platform_manager",
    "DB_USER=postgres",
    "DB_PASSWORD=password"
  ])
  ports {
    internal = "80"
    external = "80"
  }
  networks_advanced {
    name    = docker_network.multiviewer_network.name
  }

}