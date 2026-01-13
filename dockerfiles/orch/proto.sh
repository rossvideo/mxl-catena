#!/bin/bash

# run this to regenerate the grpc python files if the proto files change
# we're just commiting the generated files for simplicity

dirpath=$(dirname "$0")
cd $dirpath
mkdir -p pb
python -m grpc_tools.protoc \
    --proto_path=../landing/proto \
    --python_out=pb --grpc_python_out=pb ../landing/proto/*.proto

# fix imports
sed -i 's/import \(.*_pb2\)/from . import \1/g' pb/*_pb2.py pb/*_pb2_grpc.py
