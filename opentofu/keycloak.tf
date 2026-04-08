locals {

}
// --- container creation --------------------------------

resource "docker_container" "keycloak" {
  name  = "keycloak"
  image = docker_image.keycloak.name
  env = toset(concat([
    "KC_BOOTSTRAP_ADMIN_USERNAME=admin",
    "KC_BOOTSTRAP_ADMIN_PASSWORD=admin"
    ]
  ))
  ports {
    internal = 8080
    external = 8080
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
  command = ["start-dev"]
}

resource "null_resource" "wait_for_keycloak" {
  depends_on = [docker_container.keycloak]

  provisioner "local-exec" {
    command = <<EOT
until curl -s http://${var.target_ip}:8080/realms/master; do
  echo "Waiting for Keycloak..."
  sleep 5
done
EOT
  }
}

resource "keycloak_realm" "catena" {
  realm = "catena"

  default_signature_algorithm = "ES256"
}

resource "keycloak_realm_keystore_ecdsa_generated" "es256" {
  realm_id           = keycloak_realm.catena.id
  name               = "ecdsa-generated-es256"
  enabled            = true
  active             = true
  elliptic_curve_key = "P-256"
}

#############################################
# Scopes (one realm role per scope)
#############################################
variable "catena_scopes" {
  type = list(string)
  default = [
    "st2138:mon",
    "st2138:mon:w",
    "st2138:cfg",
    "st2138:cfg:w",
    "st2138:op",
    "st2138:op:w",
    "st2138:adm",
    "st2138:adm:w"
  ]
}

resource "keycloak_openid_client" "backend" {
  realm_id    = keycloak_realm.catena.id
  client_id   = "catena-backend"
  name        = "Catena Backend"
  description = "Client for Catena backend resource server"
  enabled     = true
  access_type = "CONFIDENTIAL"
}

resource "keycloak_role" "backend_access_role" {
  realm_id    = keycloak_realm.catena.id
  client_id   = keycloak_openid_client.backend.id
  name        = "backend-access"
  description = "Grants access to the Catena backend API."
}

resource "keycloak_openid_client_scope" "catena_scopes" {
  realm_id               = keycloak_realm.catena.id
  for_each               = toset(var.catena_scopes)
  name                   = each.key
  description            = "Grant access to ${each.key} scope"
  include_in_token_scope = true
}

resource "keycloak_role" "scope_roles" {
  realm_id    = keycloak_realm.catena.id
  for_each    = toset(var.catena_scopes)
  name        = each.key
  description = "Grants the ${each.key} scope."
}

resource "keycloak_generic_role_mapper" "catena_scopes" {
  realm_id        = keycloak_realm.catena.id
  for_each        = toset(var.catena_scopes)
  client_scope_id = keycloak_openid_client_scope.catena_scopes[each.key].id
  role_id         = keycloak_role.scope_roles[each.key].id
}

resource "keycloak_openid_client" "dashboard" {
  realm_id    = keycloak_realm.catena.id
  client_id   = "dashboard"
  name        = "Dashboard"
  description = "Client for Users to authenticate in Dashboard"
  enabled     = true
  access_type = "PUBLIC"

  standard_flow_enabled = true

  # DB rediects to a localhost URL in its flow
  root_url            = "http://localhost:3690"
  valid_redirect_uris = ["/*"]
}

resource "keycloak_openid_client_default_scopes" "default_scopes" {
  realm_id       = keycloak_realm.catena.id
  client_id      = keycloak_openid_client.dashboard.id
  default_scopes = var.catena_scopes
}

resource "keycloak_openid_audience_resolve_protocol_mapper" "audience_mapper" {
  realm_id  = keycloak_realm.catena.id
  client_id = keycloak_openid_client.dashboard.id
  name      = "Audience Mapper"
}

resource "keycloak_openid_full_name_protocol_mapper" "full_name_mapper" {
  realm_id  = keycloak_realm.catena.id
  client_id = keycloak_openid_client.dashboard.id
  name      = "Full Name"
}

resource "keycloak_openid_user_property_protocol_mapper" "username_mapper" {
  realm_id      = keycloak_realm.catena.id
  client_id     = keycloak_openid_client.dashboard.id
  name          = "Username"
  user_property = "username"
  claim_name    = "preferred_username"
}

resource "keycloak_openid_user_property_protocol_mapper" "email_mapper" {
  realm_id      = keycloak_realm.catena.id
  client_id     = keycloak_openid_client.dashboard.id
  name          = "Email"
  user_property = "email"
  claim_name    = "email"
}

##############################################
# Users and groups
##############################################

locals {
  groups = {
    "commissioners" : [
      "st2138:mon", "st2138:mon:w",
      "st2138:cfg", "st2138:cfg:w",
      "st2138:op", "st2138:op:w",
      "st2138:adm", "st2138:adm:w"
    ],
    "it-admins" : [
      "st2138:mon", "st2138:mon:w",
      "st2138:op",
      "st2138:cfg", "st2138:cfg:w"
    ],
    "journalists" : [
      "st2138:mon", "st2138:mon:w",
      "st2138:op", "st2138:op:w",
      "st2138:cfg"
    ],
    "runners" : [
      "st2138:mon",
      "st2138:op"
    ],
    "producers" : [
      "st2138:mon", "st2138:mon:w",
      "st2138:op",
      "st2138:cfg"
    ],
    "tech-dirs" : [
      "st2138:mon", "st2138:mon:w",
      "st2138:op", "st2138:op:w",
      "st2138:cfg", "st2138:cfg:w",
      "st2138:adm"
    ]
  }
  users = [{
    uid      = "apatel"
    first    = "Aisha"
    last     = "Patel"
    password = "1234"
    group    = "commissioners"
    }, {
    uid      = "egrayson"
    first    = "Elliot"
    last     = "Grayson"
    password = "1234"
    group    = "runners"
    }, {
    uid      = "jrichter"
    first    = "Jonas"
    last     = "Richter"
    password = "1234"
    group    = "it-admins"
    }, {
    uid      = "ncaldwell"
    first    = "Nina"
    last     = "Caldwell"
    password = "1234"
    group    = "tech-dirs"
    }, {
    uid      = "svoss"
    first    = "Samantha"
    last     = "Voss"
    password = "1234"
    group    = "journalists"
    }, {
    uid      = "vnavarro"
    first    = "Victor"
    last     = "Navarro"
    password = "1234"
    group    = "producers"
  }]
}

resource "keycloak_group" "groups" {
  realm_id = keycloak_realm.catena.id
  for_each = toset(keys(local.groups))
  name     = each.key
}

resource "keycloak_group_roles" "scope_mappings" {
  realm_id = keycloak_realm.catena.id
  for_each = local.groups
  group_id = keycloak_group.groups[each.key].id
  role_ids = [for scope in each.value : keycloak_role.scope_roles[scope].id]
}

resource "keycloak_user" "users" {
  for_each       = { for user in local.users : user.uid => user }
  realm_id       = keycloak_realm.catena.id
  enabled        = true
  username       = each.key
  email          = "${each.value.first}.${each.value.last}@example.com"
  email_verified = true
  first_name     = each.value.first
  last_name      = each.value.last
  initial_password {
    value     = each.value.password
    temporary = false
  }
}

resource "keycloak_user_groups" "user_group_mappings" {
  count     = length(local.users)
  realm_id  = keycloak_realm.catena.id
  user_id   = keycloak_user.users[local.users[count.index].uid].id
  group_ids = [keycloak_group.groups[local.users[count.index].group].id]
}

resource "keycloak_user_roles" "user_role_mappings" {
  realm_id = keycloak_realm.catena.id
  for_each = toset([for user in local.users : user.uid])
  user_id  = keycloak_user.users[each.key].id
  role_ids = [keycloak_role.backend_access_role.id]
}
