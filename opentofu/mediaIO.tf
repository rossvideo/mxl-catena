# resource "docker_image" "mariadb" {
#   name         = "mariadb:latest"
#   keep_locally = true
  
# }

# resource "docker_container" "mariadb" {
#   name  = "mariadb"
#   image = docker_image.mariadb.name
#   env = [
#     "MARIADB_ROOT_PASSWORD=password",
#     "MARIADB_DATABASE=mediaio",
#   ]
#   networks_advanced {
#     name = docker_network.multiviewer_network.name
#   }
#   # volumes {
#   #   host_path = "${var.workspace_dir}/external/sql/indigo_init.sql"
#   #   container_path = "/docker-entrypoint-initdb.d/00_init.sql"
#   # }

#   ports {
#     internal = "80"
#     external = "25565"
#   }
#   ports {
#     internal = "3306"
#     external = "3306"
#   }
#   log_opts ={
#     "max-file" = "3",
#     "max-size" = "10m"
#   }
# }

# resource "null_resource" "mediadb_init" {
#   depends_on = [docker_container.mariadb]
#   triggers = {
#     target_ip  = var.target_ip
#     mariadb_id = docker_container.mariadb.id
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#     until mysql --ssl=0 -h ${var.target_ip} -P 3306 -u root -ppassword -e "SELECT 1"; do
#       echo "Waiting for MariaDB..."
#       sleep 1
#     done
#     mysql --ssl=0 -h ${var.target_ip} -P 3306 -u root -ppassword <<'SQL'
# /*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
# /*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
# /*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
# /*!40101 SET NAMES utf8mb4 */;
# /*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
# /*!40103 SET TIME_ZONE='+00:00' */;
# /*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
# /*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
# /*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
# /*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

# CREATE DATABASE IF NOT EXISTS mediaio;
# USE mediaio;
# DROP TABLE IF EXISTS `LICENSE_KEY`;
# /*!40101 SET @saved_cs_client     = @@character_set_client */;
# /*!40101 SET character_set_client = utf8mb4 */;
# CREATE TABLE `LICENSE_KEY` (
#   `ID` bigint(20) NOT NULL AUTO_INCREMENT,
#   `CREATED` datetime DEFAULT NULL,
#   `FEATURE_ID` varchar(190) DEFAULT NULL,
#   `KEY` varchar(190) DEFAULT NULL,
#   `LICENSED_TO` varchar(255) DEFAULT NULL,
#   `MODIFIED` datetime DEFAULT NULL,
#   `REQUEST_CODE` varchar(255) DEFAULT NULL,
#   `VERSION_ID` int(11) NOT NULL,
#   `CREATED_BY` bigint(20) DEFAULT NULL,
#   `MODIFIED_BY` bigint(20) DEFAULT NULL,
#   `NODE` bigint(20) DEFAULT NULL,
#   PRIMARY KEY (`ID`)
# ) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

# --
# -- Dumping data for table LICENSE_KEY
# --

# /*!40000 ALTER TABLE LICENSE_KEY DISABLE KEYS */;
# INSERT INTO LICENSE_KEY VALUES
# (1,'2026-03-17 20:25:05','210',NULL,NULL,'2026-03-17 20:25:05','V-QJVBX-LB0XE-FDVF1',0,2,2,2),
# (2,'2026-03-17 20:25:05','200','60SVY-7FY5R-SSWR7-XN996','Nathan Rochon','2026-03-17 20:25:23','T-0E6X7-PRSBV-S9BE4',1,2,1,2),
# (3,'2026-03-17 20:25:05','1','7KZRN-WE9DN-0RLWE-N74DV','Nathan Rochon','2026-03-17 20:25:23','7-5N3V9-MCGT5-26415',1,2,1,2),
# (4,'2026-03-17 20:25:05','2','L661G-8VQLC-F2WJ4-G15WT','Nathan Rochon','2026-03-17 20:25:23','P-7RJ4F-SGG3G-P5F3V',1,2,1,2),
# (5,'2026-03-17 20:25:05','100','L0ETJ-H10TM-22T0X-H8FV9','Nathan Rochon','2026-03-17 20:25:23','F-YNLDQ-E7X4L-GQJEZ',1,2,1,2),
# (6,'2026-03-17 20:25:23','0','PQSDW-1RB6W-QVZBV','Nathan Rochon','2026-03-17 20:25:23',NULL,1,1,1,NULL);
# /*!40000 ALTER TABLE `LICENSE_KEY` ENABLE KEYS */;
# /*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

# /*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
# /*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
# /*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
# /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
# /*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
# /*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
# /*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
# SQL
#     EOT
#   }
  
# }

# # docker image for MediaIO Indigo
# resource "docker_image" "indigo" {
#   depends_on = [ null_resource.mediadb_init ]
#   name         = "indigo:latest"
#   build {
#     context    = "${var.workspace_dir}/external/media"
#     dockerfile = "Dockerfile.indigo"
#   }
#   # keep_locally = true
#   force_remove = true

# }
# resource "docker_container" "indigo" {
#   depends_on = [docker_image.indigo]
#   name  = "indigo"
#   image = docker_image.indigo.name
#   network_mode="container:${docker_container.mariadb.id}"
#   volumes {
#     host_path      = "${var.workspace_dir}/external/media/YourTV_Cornwall.mp4"
#     container_path = "/data/YourTV_Cornwall.mp4"
#     read_only      = false
#   }
#   log_opts ={
#     "max-file" = "3",
#     "max-size" = "10m"
#   }
  
# }

# Docker image for MediaIO engine
resource "docker_image" "engine" {
  name = "rossvideo/mediaio:subversion"
  build {
    context    = "${var.workspace_dir}/external/media"
    dockerfile = "Dockerfile.engine"
  }
  force_remove = true
}
resource "docker_container" "engine" {
  name  = "engine"
  image = docker_image.engine.name
  ports {
    internal = "8180"
    external = "8180"
  }
  volumes {
    host_path      = local.MXL_DOMAIN
    container_path = "${local.MXL_DOMAIN}/mxl"
    read_only      = false
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/media/Settings.json"
    container_path = "/root/Settings.json"
    read_only      = false
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/media/clips"
    container_path = "/data"
    read_only      = false
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
  stop_signal = "SIGINT"
  stop_timeout = 60
}


# Catena Controler
resource "null_resource" "wait_for_engine" {
  depends_on = [docker_container.engine]

  provisioner "local-exec" {
    command = <<EOT
    echo "Waiting for MediaIO Engine to be ready..."

    until curl -s -i -N \
      -H "Connection: Upgrade" \
      -H "Upgrade: websocket" \
      -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
      -H "Sec-WebSocket-Version: 13" \
      http://10.62.152.123:8180/interface 2>/dev/null | grep -q "101 Switching Protocols"
    do
      echo "MediaIO Engine not ready yet, retrying in 1 second..."
      sleep 1
    done

    echo "MediaIO Engine is ready!"
    EOT
  }
}

resource "docker_image" "MIO_controller" {
  depends_on = [ null_resource.wait_for_engine ]
  name = "rossvideo/mediaio-catena:local"
  keep_locally = true
}
resource "docker_container" "MIO_controller" {
  name  = "MIO_controller"
  image = docker_image.MIO_controller.name
  ports {
    internal = 6254
    external = 7248
  }
  volumes {
    host_path      = "${var.workspace_dir}/external/media/clips"
    container_path = "/data"
    read_only      = false
  }
  volumes {
    host_path = "${local.MXL_DOMAIN}"
    container_path = "${local.MXL_DOMAIN}"
    read_only = false
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}
resource "catena_device" "MIO" {
  depends_on  = [docker_container.MIO_controller]
  device_type = "remote-grpc"
  name        = docker_container.MIO_controller.name
  slot        = 0
  address     = local.catena_endpoint
  port        = docker_container.MIO_controller.ports[0].external

  apply_all = false
  params_map = {
    "/clip_store"  = "/data"
  }

  start_command = "/start_session"
  stop_command  = "/stop_session"

  device_status {
    oid         = "/status"
    ready_value = "1"
  }
}