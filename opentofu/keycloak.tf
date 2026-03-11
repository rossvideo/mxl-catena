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

resource "keycloak_realm" "realm" {
  depends_on = [ null_resource.wait_for_keycloak ]
  realm   = "my-realm"
  enabled = true
}
resource "keycloak_group" "parent_group" {
  realm_id = keycloak_realm.realm.id
  name     = "parent-group"
}

resource "keycloak_group" "child_group" {
  realm_id  = keycloak_realm.realm.id
  parent_id = keycloak_group.parent_group.id
  name      = "child-group"
}

resource "keycloak_group" "child_group_with_optional_attributes" {
  realm_id   = keycloak_realm.realm.id
  parent_id  = keycloak_group.parent_group.id
  name       = "child-group-with-optional-attributes"
  attributes = {
    "foo" = "bar"
    "multivalue" = "value1##value2"
  }
}