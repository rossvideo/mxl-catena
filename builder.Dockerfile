FROM golang:1.22

# Install build essentials and protoc
RUN apt-get update && apt-get install -y --no-install-recommends \
    make git ca-certificates protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Install Go protoc plugins (protoc-gen-go, protoc-gen-go-grpc)
# These are needed by the Makefile target `proto-gen`
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.1 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0

# Ensure GOPATH/bin is on PATH so protoc can find plugins
ENV PATH=/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Default to an interactive shell; commands will be provided by docker-compose
CMD ["bash"]
