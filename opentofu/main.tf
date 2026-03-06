locals {
  catena_endpoint = "http://10.62.152.123"
  // MXL DEMO 
  ndi_ports = ["5960", "5961", "5962", "5963", "5964", "5965", "5966", "5967", "5968", "5969"]
  MXL_DOMAIN = "/dev/shm"

  CATENA_INPUTS = [
    {
      container_name = "ross_ts2mxl_container"
      external_port = "7249"
      label = "Ross Logo Splash"
      ts_file_path = "/ts/Ross_Loop_logo.ts"
      uuid = "8c2d86e7-9c19-4e5a-ac9e-000020260129" 
    },
    {
      container_name = "ross2_ts2mxl_container"
      external_port = "7250"
      label = "Ross Logo"
      ts_file_path = "/ts/ross_logo_loop2.ts"
      uuid = "025aebb9-d330-f84d-a2cd-000020260129" 
    },
    {
      container_name = "madden_bowl_ts2mxl_container"
      external_port = "7251"
      label = "Madden Bowl"
      ts_file_path = "/ts/Madden_Bowl.ts"
      uuid = "24328f33-d330-c9ec-83c5-000020260129" 
    },
    {
      container_name = "sofi_stadium_ts2mxl_container"
      external_port = "7252"
      label = "Sofi Stadium"
      ts_file_path = "/ts/SoFi_Stadium.ts"
      uuid = "a42c729c-d330-efc4-9c11-000020260129" 
    },
    {
      container_name = "zsc_lions_short_ts2mxl_container"
      external_port = "7253"
      label = "ZSC Lions Short"
      ts_file_path = "/ts/ZSC_Lions_Short.ts"
      uuid = "896729f3-d330-73cf-1a5c-000020260129"
    }
  ]
  // Multiviewer
  ECR_REGISTRY = "905418485545.dkr.ecr.us-east-1.amazonaws.com"
  ECR_REGION = "us-east-1"
  MXL_TAG = "0.1.0-c66cb47f"
  DISTCESSNA_TAG = "0.0.1-18deca61"
  CHEETAH_LITE_TAG = "0.0.1-e094080b"
}

// Docker images for MXL Catena components
resource "docker_image" "mxl2ndi" {
  name = "ghcr.io/rossvideo/mxl-catena:mxl2ndi_sink"
  keep_locally = true
}

resource "docker_image" "ts2mxl" {
  name = "ghcr.io/rossvideo/mxl-catena:ts2mxl"
  keep_locally = true
}
// Docker images for Multiviewer
resource "docker_image" "control" {
  name = "${local.ECR_REGISTRY}/distcessna/control:${local.DISTCESSNA_TAG}"
  keep_locally = true
}

resource "docker_image" "cheetah_lite" {
  name = "${local.ECR_REGISTRY}/distcessna/cheetah-lite:${local.CHEETAH_LITE_TAG}"
  keep_locally = true
}

resource "docker_image" "multiviewer" {
  name = "${local.ECR_REGISTRY}/distcessna/multiviewer:${local.DISTCESSNA_TAG}"
  keep_locally = true
}

resource "docker_image" "mxl_input" {
  name = "${local.ECR_REGISTRY}/distcessna/mxl-input:${local.MXL_TAG}"
  keep_locally = true
}

resource "docker_image" "mxl_output" {
  name = "${local.ECR_REGISTRY}/distcessna/mxl-output:${local.MXL_TAG}"
  keep_locally = true
}
resource "docker_image" "mxl_tools" {
  name = "${local.ECR_REGISTRY}/distcessna/mxl-tools:${local.MXL_TAG}"
  keep_locally = true
  
}
//Docker network for Multiviewer
resource "docker_network" "multiviewer_network" {
  name = "multiviewer_network"
}

// Grafana and Prometheus for monitoring

resource "docker_image" "prometheus" {
  name = "prom/prometheus:v3.2.1"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name = "grafana/grafana:12.3.3"
  keep_locally = true
}