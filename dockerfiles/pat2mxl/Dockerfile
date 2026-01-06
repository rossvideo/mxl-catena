# Minimal container for the test_bars service
FROM ubuntu:24.04

COPY ./mxl /mxl

WORKDIR /mxl/app

ENV LD_LIBRARY_PATH=/mxl/app:/mxl/ndi/lib

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    gstreamer1.0-plugins-good \
    gstreamer1.0-x \
    && rm -rf /var/lib/apt/lists/*

# Execute mxl-info directly; pass args via compose `command`.
ENTRYPOINT ["/mxl/app/mxl-gst-videotestsrc", "-v", "/mxl/app/v210_flow2.json", "-d", "/dev/shm/mxl", "-t", "Catena MXL Demo"]
