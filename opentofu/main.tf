locals {
  ndi_ports = ["5960", "5961", "5962", "5963", "5964", "5965", "5966", "5967", "5968", "5969"]
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
