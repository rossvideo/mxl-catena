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

    "panels" : concat(
      [ // Overall
        {
          "title" : "Overall",
          "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 0 },
          "type" : "row"
        },
        { // Overall FPS Gauge
          "title" : "FPS",
          "type" : "gauge",
          "gridPos" : { "h" : 7, "w" : 3, "x" : 0, "y" : 0 },
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
              "max" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN -(local.CONTROL.RATE_DEN/10))}",
              "min" : 0,
              "thresholds" : {
                "mode" : "absolute",
                "steps" : [
                  { "color" : "red" },
                  { "color" : "yellow", "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}" },
                  { "color" : "green", "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}" }
                ]
              },
              "unit" : "fps"
            }
          }
        },
        { // Output Grains Written/s
          "title" : "Grains Written/s",
          "gridPos" : { "h" : 7, "w" : 3, "x" : 3, "y" : 0 },
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
              "max" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN -(local.CONTROL.RATE_DEN/10))}",
              "min" : 0,
              "thresholds" : {
                "mode" : "absolute",
                "steps" : [
                  { "color" : "red" },
                  { "color" : "yellow", "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}" },
                  { "color" : "green", "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}" }
                ]
              }
            }
          }
        },
        { // Overall Drops Counter stat
          "title" : "Drops Counter",
          "type" : "stat",
          "gridPos" : { "h" : 7, "w" : 3, "x" : 0, "y" : 7 },
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
                  { "color" : "green" },
                  { "color" : "red", "value" : 1.1754943508222875e-38 }
                ]
              }
            }
          }
        },
         { // Output Drops Gauge
          "title" : "Drops",
          "gridPos" : { "h" : 7, "w" : 3, "x" : 3, "y" : 7 },
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
                  { "color" : "green" },
                  { "color" : "red", "value" : 1.1754943508222875e-38 }
                ]
              },
              "unit" : "%"
            }
          }
        },
        { // Unique Grains Written/s timeseries
          "title" : "Unique Grains Written/s",
          "gridPos" : { "h" : 7, "w" : 24, "x" : 0, "y" : 14 },
          "type" : "timeseries",
          "targets" : concat([
            {
              "expr" : "FpsGauge{instance=\"output:${local.OUTPUTS.port2}\"} - InvalidGrainsPerSec{instance=\"output:${local.OUTPUTS.port2}\"}",
              "legendFormat" : "Output"
            },
          ],
            [for idx, input in local.INPUTS : {
              "expr" : "FpsGauge{instance=\"input${idx + 1}:${input.port2}\"} - InvalidGrainsPerSec{instance=\"input${idx + 1}:${input.port2}\"}",
              "legendFormat" : input.label
            }])
          
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
                  { "color" : "red" },
                  { "color" : "yellow", "value" : "${local.CONTROL.RATE_NUM / (local.CONTROL.RATE_DEN +(local.CONTROL.RATE_DEN/10))}" },
                  { "color" : "green", "value" : "${local.CONTROL.RATE_NUM / local.CONTROL.RATE_DEN}" }
                ]
              }
            }
          }
        },
 

      ],
      [// Control
        { // Control Row
          "title" : "Control",
          "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 14 },
          "type" : "row"
        },
        { // Control Load Gauge
          "title" : "Control",
          "gridPos" : { "h" : 7, "w" : 3, "x" : 0, "y" : 14 },
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
                  { "color" : "green" },
                  { "color" : "red", "value" : 100 }
                ]
              },
              "unit" : "%"
            }
          }
        },
      ],

      [// Inputs
        { // Inputs Row
          "title" : "Inputs",
          "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 21 },
          "type" : "row",
        },
      ],
      [for idx, input in local.INPUTS : {
              datasource = {
                uid = "Prometheus"
              }

              fieldConfig = {
                defaults = {
                  color = {
                    mode = "palette-classic"
                  }
                  custom = {
                    hideFrom = {
                      legend  = false
                      tooltip = false
                      viz     = false
                    }
                  }
                  decimals = 2
                  mappings = []
                  max      = 100
                  min      = 0
                  unit     = "%"
                }

                overrides = [
                  {
                    matcher = {
                      id      = "byName"
                      options = "Unused"
                    }
                    properties = [
                      {
                        id = "color"
                        value = {
                          fixedColor = "transparent"
                          mode       = "fixed"
                        }
                      },
                      {
                        id = "custom.hideFrom"
                        value = {
                          legend  = true
                          tooltip = true
                          viz     = false
                        }
                      }
                    ]
                  }
                ]
              }
              options = {
                displayLabels = []
                legend = {
                  displayMode = "table"
                  placement   = "right"
                  showLegend  = false
                  values      = ["value"]
                }
                pieType = "donut"
                reduceOptions = {
                  calcs  = ["lastNotNull"]
                  fields = ""
                  values = false
                }
                sort = "none"
                tooltip = {
                  hideZeros = false
                  mode      = "multi"
                  sort      = "none"
                }
              }

              pluginVersion = "12.3.3"

              targets = [
                {
                  editorMode   = "code"
                  exemplar     = false
                  expr         = "Input{instance=\"input${idx + 1}:${input.port2}\", type=~\"load\"}"
                  format       = "time_series"
                  legendFormat = "Load"
                  range        = true
                  refId        = "A"
                },
                {
                  datasource = {
                    type = "prometheus"
                    uid  = "cfj3di8xx8u80d"
                  }
                  editorMode   = "code"
                  expr         = "PixelConverter{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"}"
                  hide         = false
                  instant      = false
                  legendFormat = "V210 Decode"
                  range        = true
                  refId        = "B"
                },
                {
                  datasource = {
                    type = "prometheus"
                    uid  = "cfj3di8xx8u80d"
                  }
                  editorMode   = "code"
                  expr         = "OutputConverter{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"}"
                  hide         = false
                  instant      = false
                  legendFormat = "Proxy Creation"
                  range        = true
                  refId        = "C"
                },
                {
                  datasource = {
                    type = "prometheus"
                    uid  = "cfj3di8xx8u80d"
                  }
                  editorMode = "code"
                  expr = "clamp_min(100 - (sum(Input{instance=\"input${idx + 1}:${input.port2}\", type=~\"load\"}) + sum(PixelConverter{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"}) + sum(OutputConverter{instance=\"input${idx + 1}:${input.port2}\", type=\"load\"})), 0)"
                  hide         = false
                  instant      = false
                  legendFormat = "Unused"
                  range        = true
                  refId        = "D"
                }
              ]

              title       = input.label
              transparent = true
              type        = "piechart"
              gridPos = { "h" : 7, "w" : 3, "x" : idx%5*3, "y" : 21+floor(idx/5)*7 },
            }
      ],

      [// Output
        { // Output Row
          "title" : "Output",
          "gridPos" : { "h" : 1, "w" : 24, "x" : 0, "y" : 81 },
          "type" : "row"
        },
        { // Output Transfer
          "title" : "Transfer",
          "gridPos" : { "h" : 7, "w" : 3, "x" : 0, "y" : 82 },
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
          "gridPos" : { "h" : 7, "w" : 3, "x" : 3, "y" : 83 },
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
    )
  })
}