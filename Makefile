ifeq ($(strip $(VERSION)),)
VERSION := 0.1.0
endif
PLUGIN_NAME := terraform-provider-catena
PLUGIN_NAME_VERSIONED = $(PLUGIN_NAME)_v$(VERSION)
OS_ARCH := linux_amd64

.PHONY: build install clean

build:
	go build -buildvcs=false -o $(PLUGIN_NAME_VERSIONED)

build-smpte:
	go build -buildvcs=false -tags smpte -o $(PLUGIN_NAME_VERSIONED)

install:
	mkdir -p ~/.terraform.d/plugins/registry.opentofu.org/local/catena/$(VERSION)/$(OS_ARCH)
	cp $(PLUGIN_NAME_VERSIONED) ~/.terraform.d/plugins/registry.opentofu.org/local/catena/$(VERSION)/$(OS_ARCH)/

clean:
	rm -f $(PLUGIN_NAME) $(PLUGIN_NAME_VERSIONED)

.PHONY: docker-build docker-init docker-plan docker-apply

docker-build:
	docker compose -f compose.yml build

docker-init:
	docker compose -f compose.yml run --rm tofu init

docker-plan:
	docker compose -f compose.yml run --rm tofu plan

docker-apply:
	docker compose -f compose.yml run --rm tofu apply -auto-approve

.PHONY: proto-gen
PROTO_DIR := proto
GEN_DIR := internal/genproto
PROTO_API_URL := https://api.github.com/repos/SMPTE/st2138-a/contents/interface/proto?ref=main

proto-gen:
	@echo "Downloading .proto files from SMPTE/st2138-a ..."
	@mkdir -p $(PROTO_DIR)
	@curl -fsSL "$(PROTO_API_URL)" \
		| grep '"download_url":' \
		| sed -E 's/ *"download_url": "([^"]+)".*/\1/' \
		| grep '\.proto$$' \
		| while read url; do \
			fname=$$(basename "$$url"); \
			echo " -> $$fname"; \
			curl -fsSL "$$url" -o "$(PROTO_DIR)/$$fname"; \
		done
	@mkdir -p $(GEN_DIR)
	@if ! command -v protoc >/dev/null 2>&1; then \
		echo "Error: protoc not found. Install it (e.g., apt-get install -y protobuf-compiler)"; \
		echo "Alternatively: https://github.com/protocolbuffers/protobuf/releases"; \
		exit 2; \
	fi
	@if ! command -v protoc-gen-go >/dev/null 2>&1; then \
		echo "Error: protoc-gen-go not found. Install with: go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.1"; \
		echo "Ensure $$GOPATH/bin is in your PATH."; \
		exit 2; \
	fi
	@if ! command -v protoc-gen-go-grpc >/dev/null 2>&1; then \
		echo "Error: protoc-gen-go-grpc not found. Install with: go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0"; \
		echo "Ensure $$GOPATH/bin is in your PATH."; \
		exit 2; \
	fi
	@PROTO_FILES=$$(find $(PROTO_DIR) -type f -name '*.proto'); \
	if [ -z "$$PROTO_FILES" ]; then \
		echo "Error: no .proto files found in $(PROTO_DIR) after download."; \
		exit 2; \
	fi; \
	echo "Generating Go stubs to $(GEN_DIR) ..."; \
	protoc -I $(PROTO_DIR) \
		--go_out=$(GEN_DIR) \
		--go_opt=paths=source_relative \
		--go_opt=Mservice.proto=$(shell go list -m)/internal/genproto \
		--go_opt=Mconstraint.proto=$(shell go list -m)/internal/genproto \
		--go_opt=Mexternalobject.proto=$(shell go list -m)/internal/genproto \
		--go_opt=Mlanguage.proto=$(shell go list -m)/internal/genproto \
		--go_opt=Mdevice.proto=$(shell go list -m)/internal/genproto \
		--go_opt=Mparam.proto=$(shell go list -m)/internal/genproto \
		--go_opt=Mmenu.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_out=$(GEN_DIR) \
		--go-grpc_opt=paths=source_relative \
		--go-grpc_opt=Mservice.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_opt=Mconstraint.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_opt=Mexternalobject.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_opt=Mlanguage.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_opt=Mdevice.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_opt=Mparam.proto=$(shell go list -m)/internal/genproto \
		--go-grpc_opt=Mmenu.proto=$(shell go list -m)/internal/genproto \
		$$PROTO_FILES