#!/bin/bash
set -e

./build-ndi.sh Dockerfile.mxl2ndi_sink
./build-ndi.sh Dockerfile.ndi2mxl

echo "Saving images to mxl-ndi-images.tgz..."

docker save ghcr.io/rossvideo/mxl-catena-ndi:mxl2ndi_sink \
  ghcr.io/rossvideo/mxl-catena-ndi:ndi2mxl \
  | gzip > mxl-ndi-images.tgz
