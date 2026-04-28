locals {
  rest_imgs=[{
    tag="audiodeck",
    uri="audiodeck"
  },
  {
    tag="one-of-everything",
    uri="one-of-everything"
  },
  {
    tag="use-commands",
    uri="multiviewer"
  },
  {
    tag="status-update-JSON",
    uri="status-update-JSON"
  },
  {
    tag="discovery",
    uri="discovery"
  },
  {
    tag="audiodeck-JSON",
    uri="audiodeck-JSON"
  },
  {
    tag="use-menus",
    uri="menus"
  },
  {
    tag="status-update",
    uri="status-update"
  },
  {
    tag="asset-request",
    uri="asset-request"
  }]
}

resource "docker_image" "catena_rest_imgs" {
  for_each = { for img in local.rest_imgs : img.tag => img }
  name = "ghcr.io/rossvideo/catena:${each.value.tag}-REST-dev"
}
resource "docker_container" "catena_rests" {
  for_each = { for idx, img in local.rest_imgs : img.tag => img }
  name  = each.value.tag
  image = docker_image.catena_rest_imgs[each.key].name

  env = [
    "VIRTUAL_HOST=${each.value.uri}.${var.base_domain}",
    "VIRTUAL_PROTO=http",
    "VIRTUAL_PORT=6254"
  ]
  log_opts = {
    "max-size" = "10m",
    "max-file" = "3"
  }
  
}