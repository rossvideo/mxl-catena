resource "docker_image" "mariadb" {
  name         = "mariadb:latest"
  keep_locally = true
  
}

resource "docker_container" "mariadb" {
  name  = "mariadb"
  image = docker_image.mariadb.name
  env = [
    "MARIADB_ROOT_PASSWORD=password",
    "MARIADB_DATABASE=mediaio",
  ]
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }

  ports {
    internal = "80"
    external = "25565"
  }
  ports {
    internal = "3306"
    external = "3306"
  }
}

resource "null_resource" "mediadb_init" {
  depends_on = [docker_container.mariadb]
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
    until mysql --ssl=0 -h ${var.target_ip} -P 3306 -u root -ppassword -e "SELECT 1"; do
      echo "Waiting for MariaDB..."
      sleep 1
    done
    mysql --ssl=0 -h ${var.target_ip} -P 3306 -u root -ppassword <<'SQL'
CREATE DATABASE IF NOT EXISTS mediaio;
USE mediaio;
CREATE TABLE IF NOT EXISTS `LICENSE_KEY` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `CREATED` datetime DEFAULT NULL,
  `FEATURE_ID` varchar(190) DEFAULT NULL,
  `KEY` varchar(190) DEFAULT NULL,
  `LICENSED_TO` varchar(255) DEFAULT NULL,
  `MODIFIED` datetime DEFAULT NULL,
  `REQUEST_CODE` varchar(255) DEFAULT NULL,
  `VERSION_ID` int(11) NOT NULL,
  `CREATED_BY` bigint(20) DEFAULT NULL,
  `MODIFIED_BY` bigint(20) DEFAULT NULL,
  `NODE` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `LICENSE_KEY_NODE` (`NODE`),
  KEY `LICENSE_KEY_FEATURE_ID` (`FEATURE_ID`),
  KEY `LICENSE_KEY_KEY` (`KEY`),
  KEY `LICENSE_KEY_CREATED_BY` (`CREATED_BY`),
  KEY `LICENSE_KEY_MODIFIED_BY` (`MODIFIED_BY`)
);

--
-- Dumping data for table LICENSE_KEY
--

/*!40000 ALTER TABLE LICENSE_KEY DISABLE KEYS */;
INSERT INTO LICENSE_KEY VALUES
(1,'2026-03-17 20:25:05','210',NULL,NULL,'2026-03-17 20:25:05','V-QJVBX-LB0XE-FDVF1',0,2,2,2),
(2,'2026-03-17 20:25:05','200','60SVY-7FY5R-SSWR7-XN996','Nathan Rochon','2026-03-17 20:25:23','T-0E6X7-PRSBV-S9BE4',1,2,1,2),
(3,'2026-03-17 20:25:05','1','7KZRN-WE9DN-0RLWE-N74DV','Nathan Rochon','2026-03-17 20:25:23','7-5N3V9-MCGT5-26415',1,2,1,2),
(4,'2026-03-17 20:25:05','2','L661G-8VQLC-F2WJ4-G15WT','Nathan Rochon','2026-03-17 20:25:23','P-7RJ4F-SGG3G-P5F3V',1,2,1,2),
(5,'2026-03-17 20:25:05','100','L0ETJ-H10TM-22T0X-H8FV9','Nathan Rochon','2026-03-17 20:25:23','F-YNLDQ-E7X4L-GQJEZ',1,2,1,2),
(6,'2026-03-17 20:25:23','0','PQSDW-1RB6W-QVZBV','Nathan Rochon','2026-03-17 20:25:23',NULL,1,1,1,NULL);

SQL
    EOT
  }
  
}
# docker image for MediaIO
resource "docker_image" "media" {
  depends_on = [ null_resource.mediadb_init ]
  name         = "media:latest"
  build {
    context    = "${var.workspace_dir}/external/media"
    dockerfile = "Dockerfile.media"
  }
  # keep_locally = true
  force_remove = true
}

# then run the container to extract the MediaIO tar.gz
resource "docker_container" "media" {
  depends_on = [docker_image.media]
  name  = "media"
  image = docker_image.media.name
  network_mode="container:${docker_container.mariadb.name}"

}
