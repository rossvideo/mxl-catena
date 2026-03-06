locals {
  
}
# -------------------------------
# prometheus
# -------------------------------
resource "docker_container" "prometheus" {
    name  = "prometheus"
    image = docker_image.prometheus.name
    volumes {
        host_path      = "${var.workspace_dir}/metrics/prometheus.yml"
        container_path = "/etc/prometheus/prometheus.yml"
    }
    ports {
        internal = "9090"
        external = "9090"
    }
    networks_advanced {
        name = docker_network.multiviewer_network.name
    }
}
# -------------------------------
# grafana
# -------------------------------
resource "docker_container" "grafana" {
    name  = "grafana"
    image = docker_image.grafana.name
    ports {
        internal = "3000"
        external = "3000"
    }
    env = [
        "GF_AUTH_ANONYMOUS_ENABLED =true",
        "GF_AUTH_ANONYMOUS_ORG_ROLE = Viewer"
    ]
    volumes {
        host_path      = "${var.workspace_dir}/metrics/grafana_dashboards.yml"
        container_path = "/etc/grafana/provisioning/dashboards/dashboards.yml"
    }
    volumes {
        host_path      = "${var.workspace_dir}/metrics/grafana_template.json"
        container_path = "/var/lib/grafana/dashboards/dashboard.json"
    }
    volumes {
        host_path      = "${var.workspace_dir}/metrics/grafana_prometheus.yml"
        container_path = "/etc/grafana/provisioning/datasources/docker_grafana_prometheus.yml"
    }
    networks_advanced {
        name = docker_network.multiviewer_network.name
    }
}