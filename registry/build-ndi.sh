set -e

# check the first argument is Dockerfile.*
if [ $# -eq 0 ] || [[ $1 != Dockerfile.* ]]; then
    echo "Usage: $0 Dockerfile.<name>"
    exit 1
fi

#extract the name after Dockerfile.
DOCKERFILE_NAME="${1#Dockerfile.}"

TEMP_DIR=/tmp/mxl-builder-temp
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

docker run --rm -v $TEMP_DIR:/cache -v catena-build:/source alpine:latest cp -r /source/connections/gRPC/examples/poc/$DOCKERFILE_NAME/$DOCKERFILE_NAME /cache/

# copy over the static files as well
cp -r ~/Catena/sdks/cpp/connections/gRPC/examples/poc/$DOCKERFILE_NAME/static $TEMP_DIR/static
cp -r ~/Catena/mxl/lib $TEMP_DIR/mxl
cp -r ~/Catena/mxl/ndi/lib $TEMP_DIR/ndi
cp -r ~/Catena/mxl/tools $TEMP_DIR/tools
cp -r ./entrypoint.sh $TEMP_DIR/entrypoint.sh

if [ "$(arch)" == "x86_64" ]; then
    TARGET_ARCH="linux/amd64"
else
    TARGET_ARCH="linux/arm64"
fi
# build the image, using the temp dir as context
docker buildx build \
  -f $1 \
  --platform $TARGET_ARCH \
  -t rossvideo/mxl-catena-ndi:$DOCKERFILE_NAME \
  --target ndibaked \
  $TEMP_DIR
