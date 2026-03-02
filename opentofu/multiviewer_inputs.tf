// --- device creation --------------------------------
locals {
    INPUT1_UUID="704d0193-b074-448e-af16-f14484c64dbf"
    INPUT1_AUUID="fba2bbad-43e6-4b04-8f0c-f586e2c312af"
}
resource "docker_container" "input1"{
    name  = "mxl_input1"
    image = docker_image.mxl_input.name
    command = ["/app/mxlInput", "${local.MXL_DOMAIN}", "15000", "15100", "--uuid", "${local.INPUT1_UUID}", "--auuid", "${local.INPUT1_AUUID}"]
    ports {
        internal = "15000"
        external = "15000"
    }
    volumes {
        host_path      = "${local.MXL_DOMAIN}"
        container_path = "${local.MXL_DOMAIN}"
    }
}