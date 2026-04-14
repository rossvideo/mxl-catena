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
    read_only      = false
  }
  ports {
    internal = "9090"
    external = "9090"
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
    aliases = ["prometheus"]
  }
  env = [
    "VIRTUAL_HOST=prometheus.${var.base_domain}",
    "VIRTUAL_PORT=9090",
  ]
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
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
    "GF_AUTH_ANONYMOUS_ORG_ROLE = Viewer",
    "VIRTUAL_HOST=grafana.${var.base_domain}",
    "VIRTUAL_PORT=3000"
  ]
  networks_advanced {
    name = docker_network.multiviewer_network.name
    aliases = ["grafana"]
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }

}

// Optional (On-premise, not supported in Grafana Cloud): Create an organization
resource "grafana_organization" "org" {
  depends_on = [docker_container.grafana]
  name       = "Ross video"
}

resource "grafana_data_source" "prometheus" {
  type               = "prometheus"
  name               = "Prometheus"
  url                = "http://${docker_container.prometheus.name}:${docker_container.prometheus.ports[0].external}"
  basic_auth_enabled = false
  is_default         = true
  json_data_encoded = jsonencode({
    httpMethod = "POST"
  })
}


// Create resources (optional: within the organization)
resource "grafana_folder" "mv_folder" {
  depends_on = [ grafana_organization.org ]
  title = "Multiviewer Metrics"
}

resource "grafana_dashboard" "mv_dashboard" {
  folder = grafana_folder.mv_folder.id
  config_json = jsonencode({
    "title" : "MXL MV Monitor",
    "uid" : "cool-mxl-mv-dashboard",
    "preload" : false,
    "refresh" : "5s",
    "time" : {
      "from" : "now-15m",
      "to" : "now"
    },
    "timepicker" : {
      "refresh_intervals" : ["1s", "2s", "5s", "10s"]
    },
    "panels" : [
      { // Overall Row
        "title" : "Overall",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 0 },
        "type" : "row"
      },
      { // Overall FPS Gauge
        "title" : "FPS",
        "gridPos" : { "h" : 7, "w" : 3, "x" : 0, "y" : 1 },
        "type" : "gauge",
        "targets" : [
          {
            "expr" : "Control{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\", type=\"fps\"}",
            "instant" : true,
            "legendFormat" : "1"
          }
        ],
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 4,
            "max" :  "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN -(local.CONTROL.RATE_DEN/10))}",
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "red"
                },
                {
                  "color" : "yellow",
                  "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}"
                },
                {
                  "color" : "green",
                  "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}"
                }
              ]
            },
            "unit" : "fps"
          }
        }
      },
      { // Overall Drops Gauge
        "title" : "Drops",
        "gridPos" : { "h" : 7, "w" : 3, "x" : 3, "y" : 1 },
        "type" : "gauge",
        "targets" : [
          {
            "expr" : "DropsGauge{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\"}",
            "instant" : true,
            "legendFormat" : "1"
          }
        ],
        "options" : { "showThresholdMarkers" : false },
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 1.1754943508222875e-38
                }
              ]
            },
            "unit" : "%"
          }
        }
      },
      { // Overall Drops Counter stat
        "title" : "Drops Counter",
        "gridPos" : { "h" : 7, "w" : 3, "x" : 6, "y" : 1 },
        "type" : "stat",
        "targets" : [
          {
            "expr" : "DropsCounter{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\"}",
            "instant" : true,
            "legendFormat" : "1"
          }
        ],
        "options" : { "showThresholdMarkers" : false },
        "fieldConfig" : {
          "defaults" : {
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 1.1754943508222875e-38
                }
              ]
            }
          }
        }
      },
      { // Output Drops Row
        "title" : "Output Drops",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 8 },
        "type" : "row"
      },
      { // Output Grains Written/s
        "title" : "Grains Written/s",
        "gridPos" : { "h" : 7, "w" : 6, "x" : 0, "y" : 9 },
        "type" : "gauge",
        "targets" : [
          {
            "expr" : "FpsGauge{instance=\"output:${local.OUTPUTS.port2}\"}",
            "instant" : true,
            "legendFormat" : "Output"
          }
        ],
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 0,
            "max" : 59.94,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "red"
                },
                {
                  "color" : "yellow",
                  "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}"
                },
                {
                  "color" : "green",
                  "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}"
                }
              ]
            }
          }
        }
      },
      { // Output Drops Gauge
        "title" : "Drops",
        "gridPos" : { "h" : 7, "w" : 6, "x" : 6, "y" : 9 },
        "type" : "gauge",
        "targets" : [
          {
            "expr" : "DropsGauge{instance=\"output:${local.OUTPUTS.port2}\"}",
            "instant" : true,
            "legendFormat" : "Output"
          }
        ],
        "options" : { "showThresholdMarkers" : false },
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 1.1754943508222875e-38
                }
              ]
            },
            "unit" : "%"
          }
        }
      },
      { // Output Drops Counter
        "title" : "Drops Counter",
        "gridPos" : { "h" : 7, "w" : 6, "x" : 12, "y" : 9 },
        "type" : "stat",
        "targets" : [
          {
            "expr" : "DropsCounter{instance=\"output:${local.OUTPUTS.port2}\"}",
            "instant" : true,
            "legendFormat" : "Output"
          }
        ],
        "options" : { "showThresholdMarkers" : false },
        "fieldConfig" : {
          "defaults" : {
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 1.1754943508222875e-38
                }
              ]
            }
          }
        }
      },
      { // Unique Grains Written/s timeseries
        "title" : "Unique Grains Written/s",
        "gridPos" : { "h" : 8, "w" : 24, "x" : 0, "y" : 16 },
        "type" : "timeseries",
        "targets" : [
          {
            "expr" : "FpsGauge{instance=\"output:${local.OUTPUTS.port2}\"} - InvalidGrainsPerSec{instance=\"output:${local.OUTPUTS.port2}\"}",
            "legendFormat" : "Output"
          }
        ],
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 0,
            "min" : 0,
            "custom" : {
              "lineWidth" : 2,
              "fillOpacity" : 0,
              "lineInterpolation" : "stepAfter",
              "pointSize" : 5,
              "showPoints" : "auto"
            },
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "red"
                },
                {
                  "color" : "yellow",
                  "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}"
                },
                {
                  "color" : "green",
                  "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}"
                }
              ]
            }
          }
        }
      },
      { // Control Row
        "title" : "Control",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 24 },
        "type" : "row"
      },
      { // Control Load Gauge
        "title" : "Control",
        "gridPos" : { "h" : 5, "w" : 6, "x" : 0, "y" : 25 },
        "type" : "gauge",
        "targets" : [
          {
            "expr" : "Control{instance=\"${local.CONTROL.name}:${local.CONTROL.metric_port}\", type=\"load\"}",
            "instant" : true,
            "legendFormat" : "Control load"
          }
        ],
        "options" : { "showThresholdMarkers" : false },
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        }
      },
      { // Inputs Row
        "title" : "Inputs",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 30 },
        "type" : "row"
      },
      { // Inputs Load
        "title" : "Load",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 31 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "Input{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // Inputs V210 Decode
        "title" : "V210 Decode",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 36 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "PixelConverter{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // Inputs Proxy Creation
        "title" : "Proxy Creation",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 41 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "OutputConverter{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // Inputs Grains Read/s
        "title" : "Grains Read/s",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 46 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 0,
            "max" : 59.94,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "red"
                },
                {
                  "color" : "yellow",
                  "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}"
                },
                {
                  "color" : "green",
                  "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}"
                }
              ]
            }
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "FpsGauge{instance=\"input${idx + 1}:${input.port2}\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // Input Drops Row
        "title" : "Input Drops",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 51 },
        "type" : "row"
      },
      { // Input Drops Gauge
        "title" : "Input Drops",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 52 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 1.1754943508222875e-38
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "DropsGauge{instance=\"input${idx + 1}:${input.port2}\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // Input Drops Counter
        "title" : "Input Drops Counter",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 57 },
        "type" : "stat",
        "fieldConfig" : {
          "defaults" : {
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 1.1754943508222875e-38
                }
              ]
            }
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "DropsCounter{instance=\"input${idx + 1}:${input.port2}\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // Unique Grains Read/s timeseries
        "title" : "Unique Grains Read/s",
        "gridPos" : { "h" : 8, "w" : 24, "x" : 0, "y" : 62 },
        "type" : "timeseries",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 0,
            "min" : 0,
            "custom" : {
              "lineWidth" : 2,
              "fillOpacity" : 0,
              "lineInterpolation" : "stepAfter",
              "pointSize" : 5,
              "showPoints" : "auto"
            },
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "red"
                },
                {
                  "color" : "yellow",
                  "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}"
                },
                {
                  "color" : "green",
                  "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}"
                }
              ]
            }
          }
        },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "FpsGauge{instance=\"input${idx + 1}:${input.port2}\"} - InvalidGrainsPerSec{instance=\"input${idx + 1}:${input.port2}\"}",
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // MV Row
        "title" : "MV",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 70 },
        "type" : "row"
      },
      { // MV Transfer
        "title" : "Transfer",
        "gridPos" : { "h" : 5, "w" : 40, "x" : 0, "y" : 71 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : concat([
          for idx, input in local.INPUTS : {
            "expr" : "VideoRead{instance=\"multiviewer:${local.MULTIVIEWER.port2}\", type=\"transfer\", name=\"Src${idx}\"}",
            "instant" : true,
            "legendFormat" : "${input.label}"
          }
        ])
      },
      { // MV Load
        "title" : "Load",
        "gridPos" : { "h" : 5, "w" : 6, "x" : 0, "y" : 76 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : [
          {
            "expr" : "MultiViewer{instance=\"multiviewer:${local.MULTIVIEWER.port2}\", type=\"load\"}",
            "instant" : true,
            "legendFormat" : "MultiViewer load"
          }
        ]
      },
      { // Output Row
        "title" : "Output",
        "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 81 },
        "type" : "row"
      },
      { // Output Transfer
        "title" : "Transfer",
        "gridPos" : { "h" : 5, "w" : 6, "x" : 0, "y" : 82 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : [
          {
            "expr" : "VideoRead{instance=\"output:${local.OUTPUTS.port2}\", type=\"transfer\", name=\"Src4\"}",
            "instant" : true,
            "legendFormat" : "MV"
          }
        ]
      },
      { // Output Load
        "title" : "Load",
        "gridPos" : { "h" : 5, "w" : 6, "x" : 0, "y" : 87 },
        "type" : "gauge",
        "fieldConfig" : {
          "defaults" : {
            "decimals" : 1,
            "max" : 100,
            "min" : 0,
            "thresholds" : {
              "mode" : "absolute",
              "steps" : [
                {
                  "color" : "green"
                },
                {
                  "color" : "red",
                  "value" : 100
                }
              ]
            },
            "unit" : "%"
          }
        },
        "options" : { "showThresholdMarkers" : false },
        "targets" : [
          {
            "expr" : "Output{instance=\"output:${local.OUTPUTS.port2}\", type=\"load\"}",
            "instant" : true,
            "legendFormat" : "Output load"
          }
        ]
      }
    ]
  })
} 