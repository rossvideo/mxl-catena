# Multi-stage Dockerfile to build and test the Catena OpenTofu provider

# 1) Build the provider inside a Go builder image
FROM golang:1.22 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Build a linux_amd64 binary with versioned filename
ARG GO_BUILD_TAGS=""
RUN GOOS=linux GOARCH=amd64 go build -tags "$GO_BUILD_TAGS" -o terraform-provider-catena_v0.1.0

# 2) Minimal runtime image with OpenTofu and the built provider
FROM debian:stable-slim

ARG TOFU_VERSION=1.7.1
ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip tar && \
    rm -rf /var/lib/apt/lists/*

# Install OpenTofu CLI
RUN curl -L "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${TARGETOS}_${TARGETARCH}.zip" -o /tmp/tofu.zip \
    && unzip /tmp/tofu.zip -d /usr/local/bin \
    && rm /tmp/tofu.zip \
    && chmod +x /usr/local/bin/tofu

# Install Docker CLI (static binary) to interact with host daemon via mounted socket
# Note: Debian's docker.io package may not include the 'docker' client; use official static release instead.
RUN arch=$(dpkg --print-architecture) && \
    curl -fsSL "https://download.docker.com/linux/static/stable/$( [ "$arch" = "amd64" ] && echo x86_64 || echo $arch )/docker-25.0.5.tgz" -o /tmp/docker.tgz && \
    tar -xzf /tmp/docker.tgz -C /tmp docker/docker && \
    mv /tmp/docker/docker /usr/local/bin/docker && \
    rm -rf /tmp/docker /tmp/docker.tgz && \
    chmod +x /usr/local/bin/docker

# Copy built provider into the filesystem mirror path
ENV HOME=/root
RUN mkdir -p $HOME/.terraform.d/plugins/registry.opentofu.org/local/catena/0.1.0/linux_amd64
COPY --from=builder /src/terraform-provider-catena_v0.1.0 $HOME/.terraform.d/plugins/registry.opentofu.org/local/catena/0.1.0/linux_amd64/terraform-provider-catena_v0.1.0
RUN chmod +x $HOME/.terraform.d/plugins/registry.opentofu.org/local/catena/0.1.0/linux_amd64/terraform-provider-catena_v0.1.0

# Configure Terraform/OpenTofu to use local plugin mirror
COPY terraformrc /root/.terraformrc

# Workdir where examples will be mounted
WORKDIR /workspace

# Default command: show tofu version
CMD ["tofu", "version"]
