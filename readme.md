# MXL Demo (OpenTofu + Catena)

This repository deploys a Catena/MXL demo stack using OpenTofu and Docker. It includes:

- A local custom OpenTofu provider (`local/catena`, version `0.1.0`)
- Catena TS to MXL and MXL to NDI containers
- Multiviewer-related containers
- Prometheus and Grafana containers

The main operator entry point is the `./tofu` wrapper script.

## Current Default Topology

The repository is currently configured for a remote Docker/Catena host:

- Docker provider host: `ssh://ansible@10.62.152.123`
- Catena endpoint: `10.62.152.123` (gRPC)
- Grafana endpoint: `http://10.62.152.123:3000`

If you are not using that host, update the files listed in [Configuration You Will Likely Change](#configuration-you-will-likely-change).

## Prerequisites

- Linux host with Docker Engine and Docker Compose v2 (`docker compose`)
- Access to a target Docker host (or adjust config for local Docker)
- SSH private key available at `~/IAC/.ssh/id_ed25519` (as currently referenced)
- OpenTofu is not required on the host machine (it runs inside the `tofu` container)
- NDI Advanced SDK Linux installer script (`Install_*.sh`) to stage `external/ndi` assets
- MP4 source files (optional) if you want to generate `.ts` files with `ts-builder.sh`

## Remote vs local dev
for remote server:
  - setup access token [link to access tokens][https://srvottgitlab02.rossvideo.com/-/user_settings/personal_access_tokens]
  - make `tofu.env` and put
  ```yml
    USERNAME="your.gitlab.username"
    PASSWORD="Personal access token with api, read_api"
  ```
  - change `opentofu/backend.tf` to use your own state (not demo1)
  - change `target_server.auto.tfvars` to be your target server
for local server:
 - delete `opentofu/backend.tf`
 - anytime it says to do `./tofu setup` do `./tofu init`
 - dont run `./upload` run `import_multivewer.sh`

---
## Quick Start
- From the repository root:

```bash
# 1) Stage external runtime assets
./ndi-builder.sh
./ts-builder.sh
./upload.sh

# 2) Build provider + runtime images
./tofu build

# 3) Initialize OpenTofu workspace
./tofu setup

# 4) Apply the stack
./tofu start
```

To stop and tear down:

```bash
./tofu stop
```

Note: `./tofu stop` performs `tofu destroy -auto-approve`. It does not currently clean remote `/dev/shm` automatically.

## `./tofu` Command Reference

Project commands:

- `./tofu build` - build provider in builder container, then build runtime image
- `./tofu setup` - remove lock file, ensure image exists, run `tofu init`
- `./tofu run` or `./tofu start` - run `tofu apply -auto-approve`
- `./tofu end` or `./tofu stop` - run `tofu destroy -auto-approve`

Pass-through OpenTofu commands (examples):

- `./tofu plan`
- `./tofu apply`
- `./tofu destroy`
- `./tofu validate`
- `./tofu fmt`
- `./tofu state`

Shell utilities:

- `./tofu --shell bash`
- `./tofu --it bash`
- `./tofu --inject bash`

## Configuration You Will Likely Change

The repo contains environment-specific defaults. Update these for your setup:

- `compose.yml`
  - SSH key bind mount path (`~/IAC/.ssh/id_ed25519`)
- `opentofu/providers.tf`
  - Docker SSH target
  - Catena endpoint
  - Grafana URL/auth
- `opentofu/main.tf`
  - `local.catena_endpoint`
  - input list (`local.CATENA_INPUTS`) and labels/ports/UUIDs
- `upload.sh`
  - `TARGET_SERVER`, `SSH_KEY`, `TARGET_DIR`
- `clean_server.sh`
  - `TARGET_SERVER`, `SSH_KEY`

## External Assets

- `external/ndi` is populated by `./ndi-builder.sh`
  - Requires `external/ndi/Install_*.sh` (NDI Advanced SDK Linux installer)
  - Copies `libndi.so`, `libndi.so.6`, `libndi.so.6.0.0`
- `external/ts` is populated by `./ts-builder.sh`
  - Converts `*.mp4` from repo root into transport streams via containerized ffmpeg

## Remote Host Setup Helpers

- `setup server/setup.sh` - server bootstrap (user, SSH, Docker hardening)
- `setup server/readme.md` - notes for target server setup
- `upload.sh` - uploads `external/`, `images/`, `metrics/`, then runs `import_multivewer.sh` remotely
- `import_multivewer.sh` - loads tarred Docker images from `images/`

## Build and Development Notes

- Provider binary output: `terraform-provider-catena_v0.1.0`
- Provider source address served by `main.go`: `registry.opentofu.org/local/catena`
- `Makefile` targets:
  - `make build`
  - `make build-smpte`
  - `make install`
  - `make proto-gen`

`make proto-gen` reads from `proto/*.proto` and writes generated files to `internal/genproto/`.

## Repository Layout (Current)

```text
.
|- builder.Dockerfile
|- Dockerfile
|- compose.yml
|- Makefile
|- main.go
|- go.mod / go.sum
|- terraformrc
|- tofu
|- ndi-builder.sh
|- ts-builder.sh
|- upload.sh
|- clean_server.sh
|- import_multivewer.sh
|- external/
|  |- ndi/
|  `- ts/
|- images/
|- internal/
|  |- client/
|  |- datasources/
|  |- genproto/
|  |- provider/
|  `- resources/
|- metrics/
|- opentofu/
|  |- providers.tf
|  |- inputs.tf
|  |- main.tf
|  |- catena_ts2mxl.tf
|  |- catena_mxl2ndi.tf
|  |- multiviewer.tf
|  `- grafana.tf
|- proto/
|  `- *.proto
|- registry/
|  |- Dockerfile.ts2mxl
|  |- Dockerfile.mxl2ndi_sink
|  |- entrypoint.sh
|  `- build.sh
`- setup server/
```

## Troubleshooting

- Re-init workspace (removes lock first):
  ```bash
  ./tofu init
  ```
- Full recycle:
  ```bash
  ./tofu stop
  ./tofu start
  ```
- Clean remote shared memory manually if needed:
  ```bash
  ./clean_server.sh
  ```
- Fix local file ownership after container builds (if needed):
  ```bash
  sudo chown -R 1000:1000 .
  ```

## External Links

- OpenTofu: https://opentofu.org
- Docker: https://docs.docker.com/
- Go: https://go.dev/
- Protocol Buffers: https://protobuf.dev/
- gRPC for Go: https://grpc.io/docs/languages/go/
- NDI SDK: https://ndi.tv/sdk
- Catena MXL Flow Definition: https://github.com/rossvideo/Catena/blob/mxl-poc/sdks/cpp/connections/gRPC/examples/poc/templates/param.flow_def.yaml
- Catena `ts2mxl` model: https://github.com/rossvideo/Catena/blob/mxl-poc/sdks/cpp/connections/gRPC/examples/poc/ts2mxl/device.ts2mxl.yaml
- Catena `mxl2ndi_sink` model: https://github.com/rossvideo/Catena/blob/mxl-poc/sdks/cpp/connections/gRPC/examples/poc/mxl2ndi_sink/device.mxl2ndi_sink.yaml
