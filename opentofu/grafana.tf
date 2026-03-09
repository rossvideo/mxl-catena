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
        "GF_AUTH_ANONYMOUS_ENABLED = true",
        "GF_AUTH_ANONYMOUS_ORG_ROLE = Viewer"
    ]
    networks_advanced {
        name = docker_network.multiviewer_network.name
    }
}

// Optional (On-premise, not supported in Grafana Cloud): Create an organization
resource "grafana_organization" "org" {
  depends_on = [ docker_container.grafana ]
  name = "Ross video"
}

resource "grafana_data_source" "prometheus" {
  type                = "prometheus"
  name                = "Prometheus"
  url                 = "http://prometheus:9090"
  basic_auth_enabled  = false
  is_default         = true
  json_data_encoded = jsonencode({
    httpMethod = "POST"
  })
}


// Create resources (optional: within the organization)
resource "grafana_folder" "mv_folder" {
  title  = "Multiviewer Metrics"
}

resource "grafana_dashboard" "mv_dashboard" {
  folder = grafana_folder.mv_folder.id
  config_json = jsonencode({
    "title": "MXL MV Monitor",
    "uid" : "cool-mxl-mv-dashboard",
    "preload": false,
    "refresh": "5s",
    "timepicker": {
        "refresh_intervals": [ "1s", "2s", "5s", "10s"]
    },
    "panels": [
        {// Overall Row
            "title": "Overall",
            "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 },
            "type": "row"
        },
        {// Control Row
            "title": "Control",
            "gridPos": { "h": 1, "w": 24, "x": 0, "y": 16 },
            "type": "row"
        },
        {// Control FPS Gauge
            "title": "FPS",
            "gridPos": { "h": 7, "w": 3, "x": 0, "y": 1 },
            "type": "gauge"
            "targets": [
                {
                "expr": "Control{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\", type=\"fps\"}",
                "instant": true,
                "legendFormat": "1"
                }
            ],
            "fieldConfig": {
                    "defaults": {
                    "decimals": 4,
                    "max": 59.94,
                    "min": 0,
                    "thresholds": {
                        "mode": "absolute",
                        "steps": [
                        {
                            "color": "red"
                        },
                        {
                            "color": "yellow",
                            "value": 59
                        },
                        {
                            "color": "green",
                            "value": 59.9
                        }
                        ]
                    },
                    "unit": "fps"
                    }
            },
        },
        {// Control Drops Gauge
            "title": "Drops",
            "gridPos": {"h": 7, "w": 3, "x": 3, "y": 1 },
            "type": "gauge",
            "targets": [
                {
                "expr": "DropsGauge{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\"}",
                "instant": true,
                "legendFormat": "1"
                }
            ],
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                "decimals": 1,
                "max": 100,
                "min": 0,
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                    {
                        "color": "green"
                    },
                    {
                        "color": "red",
                        "value": 1.1754943508222875e-38
                    }
                    ]
                },
                "unit": "%"
                }
            },
        },
        {// Control Drops Counter stat
            "title": "Drops Counter",
            "gridPos": {"h": 7, "w": 3, "x": 6, "y": 1 },
            "type": "stat",
            "targets": [
                {
                "expr": "DropsCounter{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\"}",
                "legendFormat": "1"
                }
            ],
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                    "thresholds": {
                        "mode": "absolute",
                        "steps": [
                        {
                            "color": "green"
                        },
                        {
                            "color": "red",
                            "value": 1.1754943508222875e-38
                        }
                        ]
                    }
                }
            },
        },
        {// Control Load Gauge
            "title": "Control",
            "gridPos": {"h": 5, "w": 6, "x": 0, "y": 17 },
            "type": "gauge",
            "targets": [
                {
                    "expr": "Control{instance=\"control:14100\", type=\"load\"}",
                    "instant": true,
                    "legendFormat": "Control load"
                }
            ],
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                    "decimals": 1,
                    "max": 100,
                    "min": 0,
                    "thresholds": {
                        "mode": "absolute",
                        "steps": [
                        {
                            "color": "green"
                        },
                        {
                            "color": "red",
                            "value": 100
                        }
                        ]
                    },
                    "unit": "%"
                }
            },
        },
        {// INPUT ROW
            "title": "Inputs",
            "gridPos": { "h": 1, "w": 24, "x": 0, "y": 22 },
            "type": "row"
        },
        {// INPUT load gauges
            "title": "Load",
            "gridPos": { "h": 5, "w": 40, "x": 0, "y": 28 },
            "type": "gauge",
            "fieldConfig": {
                "defaults": {
                        "decimals": 1,
                        "max": 100,
                        "min": 0,
                        "thresholds": {
                            "mode": "absolute",
                            "steps": [
                            {
                                "color": "green"
                            },
                            {
                                "color": "red",
                                "value": 100
                            }
                            ]
                        },
                    "unit": "%"
                }
            },
            "options": { "showThresholdMarkers": false },
            "targets": concat([
                for idx, input in local.INPUTS : {
                  "expr": "Input{instance=\"input${idx+1}:${input.port2}\", type=\"load\"}",
                  "instant": true,
                  "legendFormat": "${input.label}"

                }
              ]
            )
                
                
        },
        {// INPUT V210 Decode gauges
            "title": "V210 Decode",
            "gridPos": { "h": 5, "w": 24, "x": 0, "y": 22 },
            "type": "gauge"
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                "decimals": 1,
                "max": 100,
                "min": 0,
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                    {
                        "color": "green"
                    },
                    {
                        "color": "red",
                        "value": 100
                    }
                    ]
                },
                "unit": "%"
                }
            },
            "targets": concat([
                for idx, input in local.INPUTS : {
                  "expr": "PixelConverter{instance=\"input${idx+1}:${input.port2}\", type=\"load\"}",
                  "instant": true,
                  "legendFormat": "${input.label}"

                }
              ]
            )

        },
        {// INPUT Proxy Creation gauges
            "title": "Proxy Creation",
            "type": "gauge",
            "gridPos": { "h": 5, "w": 40, "x": 0, "y": 33 },
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                "decimals": 1,
                "max": 100,
                "min": 0,
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                    {
                        "color": "green"
                    },
                    {
                        "color": "red",
                        "value": 100
                    }
                    ]
                },
                "unit": "%"
                }
            },
            "targets": concat([
                for idx, input in local.INPUTS : {
                  "expr": "OutputConverter{instance=\"input${idx+1}:${input.port2}\", type=\"load\"}",
                  "instant": true,
                  "legendFormat": "${input.label}"

                }
              ]
            )
        },
        {//MV row
            "title": "MV",
            "gridPos": { "h": 1, "w": 24, "x": 0, "y": 121},
            "type": "row"
        },
        {// MV Transfer Gauges
            "title": "Transfer",
            "gridPos": { "h": 5, "w": 40, "x": 0, "y": 122},
            "type": "gauge",
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                    "decimals": 1,
                    "max": 100,
                    "min": 0,
                    "thresholds": {
                        "mode": "absolute",
                        "steps": [
                        {
                            "color": "green"
                        },
                        {
                            "color": "red",
                            "value": 100
                        }
                        ]
                    },
                "unit": "%"
                },
            },
            "targets": concat([
                for idx, input in local.INPUTS : {
                  "expr": "VideoRead{instance=\"multiviewer:${local.MULTIVIEWER.port2}\", type=\"transfer\", name=\"Src${idx}\"}",
                  "instant": true,
                  "legendFormat": "${input.label}"
                }
            ])
            
        },
        {// MV Load Gauges
            "title": "Load",
            "gridPos": { "h": 5, "w": 6, "x": 0, "y": 137},
            "type": "gauge",
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                "decimals": 1,
                "max": 100,
                "min": 0,
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                    {
                        "color": "green"
                    },
                    {
                        "color": "red",
                        "value": 100
                    }
                    ]
                },
                "unit": "%"
                }
            },
            "targets": [
                {
                "expr": "MultiViewer{instance=\"multiviewer:${local.MULTIVIEWER.port2}\", type=\"load\"}",
                "instant": true,
                "legendFormat": "MultiViewer load"
                }
            ],
        },
        {//Output row
            "title": "Output",
            "gridPos": { "h": 1, "w": 24, "x": 0, "y": 142},
            "type": "row"
        },
        {// Output Transfer Gauges
            "title": "Transfer",
            "gridPos": { "h": 5, "w": 6, "x": 0, "y": 143 },
            "type": "gauge",
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                "decimals": 1,
                "max": 100,
                "min": 0,
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                    {
                        "color": "green"
                    },
                    {
                        "color": "red",
                        "value": 100
                    }
                    ]
                },
                "unit": "%"
                }
            },
            "targets": [
                {
                "expr": "VideoRead{instance=\"output:${local.OUTPUTS.port2}\", type=\"transfer\", name=\"Src4\"}",
                "instant": true,
                "legendFormat": "MV"
                }
            ]
        },
        {// Output Load Gauge
            "title": "Load",
            "gridPos": { "h": 5, "w": 6, "x": 0, "y": 153 },
            "type": "gauge",
            "options": { "showThresholdMarkers": false },
            "fieldConfig": {
                "defaults": {
                "decimals": 1,
                "max": 100,
                "min": 0,
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                    {
                        "color": "green"
                    },
                    {
                        "color": "red",
                        "value": 100
                    }
                    ]
                },
                "unit": "%"
                }
            },
            "targets": [
                {
                "expr": "Output{instance=\"output:${local.OUTPUTS.port2}\", type=\"load\"}",
                "instant": true,
                "legendFormat": "Output load"
                }
            ]
        },
    ]
  })
} 