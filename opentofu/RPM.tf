# ------------------------------ Database for RPM ------------------------------
resource "docker_volume" "rpm_database_data" {
  name = "rpm_database_data"
}

resource "docker_container" "rpm_database" {
  name  = "rpm_database"
  image = docker_image.rpm_database.name

  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=password",
    "POSTGRES_DB=platform_manager",
    "POSTGRES_HOST_AUTH_METHOD=trust"
  ]

  command = [
    "postgres",
    "-c",
    "listen_addresses=*"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  networks_advanced {
    name = docker_network.multiviewer_network.name
  }
  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }
}
# ----- INIT the DATABASE
resource "null_resource" "platform_manager" {
  depends_on = [docker_container.rpm_database]
  triggers = {
    target_ip       = var.target_ip
    rpm_database_id = docker_container.rpm_database.id
  }

  provisioner "local-exec" {
    command = <<EOT
until psql "postgresql://postgres:password@${var.target_ip}:5432" -c "SELECT 1" >/dev/null 2>&1; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done
psql "postgresql://postgres:password@${var.target_ip}:5432" <<SQL
SELECT 'CREATE DATABASE platform_manager
    LOCALE_PROVIDER = icu
    ICU_LOCALE = ''und''
    ENCODING = ''UTF8''
    TEMPLATE = template0'
    WHERE NOT EXISTS (
SELECT 1 FROM pg_database WHERE datname = 'platform_manager'
)\gexec

SQL
    EOT
  }
}


resource "null_resource" "license_key_table" {
    depends_on = [ null_resource.platform_manager ]
  triggers = {
    target_ip           = var.target_ip
    platform_manager_id = null_resource.platform_manager.id
  }

  provisioner "local-exec" {
    command = <<EOT
psql "postgresql://postgres:password@${var.target_ip}:5432/platform_manager" <<SQL

CREATE TABLE public."LICENSE_KEY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "FEATURE_ID" character varying(190),
    "KEY" character varying(190),
    "LICENSED_TO" character varying(255),
    "MODIFIED" timestamp without time zone,
    "REQUEST_CODE" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "NODE" bigint
);
ALTER TABLE public."LICENSE_KEY" OWNER TO postgres;

CREATE SEQUENCE public."LICENSE_KEY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."LICENSE_KEY_ID_seq" OWNER TO postgres;

INSERT INTO public."LICENSE_KEY"
("ID","CREATED","FEATURE_ID","KEY","LICENSED_TO","MODIFIED","REQUEST_CODE","VERSION_ID","CREATED_BY","MODIFIED_BY","NODE")
VALUES 
(1,NOW(), 290, 'ZRVW4-WVJKE-FVMWK-G392L', 'Catena', NOW(), '7-GRZPE-QNQ67-MKN39', 1, 2, 1, 1),
(2,NOW(), 210, NULL, NULL, NOW(), '6-VDM70-KSZDR-HG92T', 0, 2, 2, 1),
(3,NOW(), 220, NULL, NULL, NOW(), '9-HTJ37-PN0NB-3CP3J', 0, 2, 2, 1),
(4,NOW(), 240, NULL, NULL, NOW(), '5-CBLPX-T0VJW-HM9CP', 0, 2, 2, 1),
(5,NOW(), 200, 'CN1HS-9NBFZ-X7N4S-GSRLF', 'Catena', NOW(), 'F-J8LMT-15PHV-KHT1P', 1, 2, 1, 1),
(6,NOW(), 1, '3NKWW-91PNY-7E43V-3R7S0', 'Catena', NOW(), 'J-FPB23-3JT6B-WXC7C', 1, 2, 1, 1),
(7,NOW(), 2, 'KK7VB-2F49W-6TLDG-L3K0X', 'Catena', NOW(), '1-GKQQX-YWQYH-YNBB6', 1, 2, 1, 1),
(8,NOW(), 423, '2XK33-5NYT9-0ST4G-N388Z', 'Catena', NOW(), '0-HZN4D-2K8YB-5YE0S', 1, 2, 1, 1),
(9,NOW(), 422, 'V7YEK-TR9TN-ZYMKW-W1BZJ', 'Catena', NOW(), 'M-G5SQ6-1YWPN-MZZBP', 1, 2, 1, 1),
(10,NOW(), 300, 'NZFWP-W6HGE-EPRWW-HPYNX', 'Catena', NOW(), 'R-HZDQF-1M0RD-1VKFX', 1, 2, 1, 1),
(11,NOW(), 310, '2GD53-5SZNF-K1814-550RP', 'Catena', NOW(), '1-YEGMJ-THE48-18K36', 1, 2, 1, 1),
(12,NOW(), 425, 'XV47M-7CJJV-14FNW-6JV6Z', 'Catena', NOW(), '7-SRDXD-2N7D6-MLY25', 1, 2, 1, 1),
(13,NOW(), 424, 'G3SWB-2YGPC-ZBMJX-CF36M', 'Catena', NOW(), 'P-GEDGH-81ETX-80F28', 1, 2, 1, 1),
(14,NOW(), 421, 'GBVP0-G6XXY-PNN3Y-JLGX8', 'Catena', NOW(), 'H-N7B87-QWBNL-F3BFF', 1, 2, 1, 1),
(15,NOW(), 0, '0N173-Q146H-93G7W', 'Catena', NOW(), NULL, 1, 1, 1, NULL);

SQL
EOT
  }
}
resource "null_resource" "ogp_frame_table" {
  depends_on = [null_resource.platform_manager, catena_device.ts2mxl]

  triggers = {
    target_ip = var.target_ip
    devices   = jsonencode(catena_device.ts2mxl)
  }

  provisioner "local-exec" {
    command = <<EOT
psql "postgresql://postgres:password@${var.target_ip}:5432/platform_manager" <<SQL

CREATE TABLE public."OGP_FRAME" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "HOSTNAME" character varying(255) NOT NULL,
    "PORT" integer NOT NULL,
    "PROTOCOL" character varying(255) NOT NULL,
    "USE_SSL" boolean DEFAULT false,
    "CONNECTION_SETTINGS" text,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone
);


ALTER TABLE public."OGP_FRAME" OWNER TO postgres;


CREATE SEQUENCE public."OGP_FRAME_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."OGP_FRAME_ID_seq" OWNER TO postgres;

ALTER SEQUENCE public."OGP_FRAME_ID_seq" OWNED BY public."OGP_FRAME"."ID";
ALTER TABLE public."OGP_FRAME"
ALTER COLUMN "ID" SET DEFAULT nextval('public."OGP_FRAME_ID_seq"');

TRUNCATE TABLE public."OGP_FRAME" RESTART IDENTITY;

INSERT INTO public."OGP_FRAME"
("NAME","HOSTNAME","PORT","PROTOCOL","USE_SSL","CONNECTION_SETTINGS","CREATED","MODIFIED")
VALUES
('Authz', 'authz.${var.base_domain}', 443, 'CATENA', true, '<properties><entry key="node-id">authz.${var.base_domain}:443</entry></properties>', NOW(), NOW()),
('${catena_device.mxl2ndi.name}','mxl2ndi.${var.base_domain}',443,'CATENA',true,'<properties><entry key=\"node-id\">mxl2ndi.${var.base_domain}:443</entry></properties>',NOW(),NOW()),
('Media IO','mio-controller.${var.base_domain}',443,'CATENA',true,'<properties></properties>',NOW(),NOW()),
('${catena_device.ndi2mxl.name}','ndi2mxl.${var.base_domain}',443,'CATENA',true,'<properties><entry key=\"node-id\">ndi2mxl.${var.base_domain}:443</entry></properties>',NOW(),NOW()),
('${catena_device.cheetah.name}','cheetah.${var.base_domain}',443,'CATENA',true,'<properties><entry key=\"node-id\">cheetah.${var.base_domain}:443</entry></properties>',NOW(),NOW()),
('${catena_device.ssg.name}','ssg.${var.base_domain}',443,'CATENA',true,'<properties><entry key=\"node-id\">ssg.${var.base_domain}:443</entry></properties>',NOW(),NOW()),
${join(",\n", [
  for input in local.CATENA_INPUTS  :
  "( '${input.label}', '${input.uri}.${var.base_domain}', 443, 'CATENA', true, '<properties><entry key=\"node-id\">${input.uri}.${var.base_domain}:443</entry></properties>', NOW(), NOW())"
])}
;

SQL
EOT
  }
}
# -------------------- RPM
resource "docker_image" "rpm" {
  name = "rpm:latest"

  build {
    context    = "${var.workspace_dir}/external/rpm"
    dockerfile = "Dockerfile.rpm"
    tag     = ["rpm:latest"]
  }
  keep_locally = true
}

resource "docker_container" "rpm" {
  depends_on = [docker_container.rpm_database, docker_image.rpm]

  name  = "rpm"
  image = docker_image.rpm.name

  ports {
    internal = "80"
    external = "80"
  }
  networks_advanced {
    name = docker_network.multiviewer_network.name
  }

  env = [
    "VIRTUAL_HOST=rpm.${var.base_domain}",
    "VIRTUAL_PROTO=http",
    "VIRTUAL_PORT=80",
  ]

  log_opts ={
    "max-file" = "3",
    "max-size" = "10m"
  }

}