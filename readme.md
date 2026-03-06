# MXL Demo (OpenTofu)

A containerized demo that uses OpenTofu to spin up and manage Catena/MXL processing pipelines. It bundles a custom OpenTofu provider (local), NDI tooling, and transport stream sources to assemble a working demo stack.
---
## Normal Start/Stop
```bash
# Start the stack
./tofu start

# Stop and clean shared memory files
./tofu stop
```
---
## Project Tree
```
.
├─ builder.Dockerfile           # Build toolchain image (Go/Make/protoc)
├─ Dockerfile                   # Runtime image for tofu service
├─ compose.yml                  # Docker Compose services (tofu, builder)
├─ Makefile                     # Provider build/install + proto generation
├─ main.go                      # Provider entry point
├─ README.md                    # Quickstart notes
├─ go.mod / go.sum              # Go module metadata
├─ terraformrc                  # Tofu/Terraform CLI configuration (local registry)
├─ ndi-builder.sh               # Helper to build NDI artifacts
├─ ts-builder.sh                # Helper to build TS artifacts
├─ tofu                         # Convenience wrapper for OpenTofu in Docker
├─ external/
│  ├─ ndi/                      # NDI Advanced SDK v6 Linux assets
│  │  ├─ Install_NDI_Advanced_SDK_v6_Linux.sh   # The NDI install script you need to supply
│  │  └─ ...
│  └─ ts/                       # Demo transport streams
│     ├─ ross_logo_loop2.ts
│     └─ ...
├─ internal/                    # Source code for the Tofu provider
│  ├─ client/                   # Client helpers (e.g., SMPTE)
│  ├─ datasources/genproto/     # Generated protobuf stubs
│  ├─ provider/                 # Provider wiring
│  └─ resources/                # Provider resources
├─ opentofu/
│  ├─ main.tf                   # Demo stack
│  ├─ providers.tf              # Local provider registry
│  ├─ inputs.tf                 # Input variables
│  ├─ catena_*.tf               # Catena devices used in the demo
│  └─ terraform.tfstate*        # State files
├─ protos/
│  ├─ download_protos.sh        # helper script for downloading the st2138 protos
|  └─ ...
└─ registry/
   ├─ Dockerfile.ts2mxl         # TS→MXL pipeline container
   ├─ Dockerfile.mxl2ndi_sink   # MXL→NDI sink container
   └─ build.sh                  # container build helper for the mxl demo catena devices

```

## Prerequisites
- Docker (Compose v2: `docker compose`)
- Git
- Linux with `/dev/shm` available (shared memory is used; the stop routine cleans `/dev/shm/mxl/*`).
- RossVideo's Dashboard


## Pulling the Project
```bash
git clone https://github.com/rossvideo/mxl-catena.git
cd mxl-catena
```

If you copied from local files rather than git, ensure subfolders under `external/ndi` and `external/ts` are present.

## First-Time Setup & Run
The builder container handles Go/Make/protoc and builds the provider and images.

```bash
# Build NDI and TS artifacts used in the demo
./ndi-builder.sh # you will need to copy the NDI install sh to the correct place (external/ndi/)
./ts-builder.sh  # if you have your own mp4's you can add them to the project root

# Build provider inside builder + runtime docker image
./tofu build

# Initialize the OpenTofu workspace inside the tofu container
./tofu init

# Start the full demo stack (apply)
./tofu start
```

Connect your dashboard to `localhost:7254` as a Catena device once the stack is up.

Notes:
- If you see permission issues on generated files, you can run:
  ```bash
  sudo chown -R 1000:1000 .
  ```
- The provider binary is written/versioned as `terraform-provider-catena_v0.1.0` in the project root during builds.

## Normal Start/Stop
```bash
# Start the stack
./tofu start

# Stop and clean shared memory files
./tofu stop
```

Additional pass-through commands are available, e.g., `./tofu plan`, `./tofu destroy`, `./tofu validate`.

## How to Contribute
- Fork the repo and create a feature branch: `feature/your-thing`
- Keep changes focused and documented (update this README if relevant)
- Follow Go conventions; run local builds via the builder container or your toolchain
- Generate protobuf stubs when `.proto` files change:
  ```bash
  ./tofu build
  ```
- Build provider (dev):
  ```bash
  ./tofu build
  ```
- Open a pull request with a clear description, rationale, and test notes

## Troubleshooting
- Most issues are solved by just:
  ```bash
  ./tofu stop
  ./tofu start
  ```
- Re-init the workspace (clears lock file):
  ```bash
  ./tofu init
  ```
- Clean shared memory leftovers after stop:
  ```bash
  ./tofu stop
  ```

## External Links
- OpenTofu: https://opentofu.org
- Docker: https://docs.docker.com/
- Go: https://go.dev/
- Protocol Buffers: https://protobuf.dev/
- gRPC for Go: https://grpc.io/docs/languages/go/
- NDI (SDK & info): https://ndi.tv/sdk
### Links for demo video sources
- TSDuck sample streams: https://tsduck.io/streams/
- VQEG video datasets: https://www.vqeg.org/video-datasets-and-organizations/
### Links to Catana data models
- [MXL Flow Definintion](https://github.com/rossvideo/Catena/blob/mxl-poc/sdks/cpp/connections/gRPC/examples/poc/templates/param.flow_def.yaml)
- [ts2mxl Device Model](https://github.com/rossvideo/Catena/blob/mxl-poc/sdks/cpp/connections/gRPC/examples/poc/ts2mxl/device.ts2mxl.yaml)
- [mxl2ndi Device Model](https://github.com/rossvideo/Catena/blob/mxl-poc/sdks/cpp/connections/gRPC/examples/poc/mxl2ndi_sink/device.mxl2ndi_sink.yaml)



---

### FAQ
#### you may need to delete the flows on the server if working in remote