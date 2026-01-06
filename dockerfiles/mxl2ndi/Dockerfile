FROM ubuntu:24.04 AS base

ARG WORKDIR=/app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libavformat60 \
    libavcodec60 \
    libavutil58 \
    libavahi-client3 \
    libavahi-common3 \
    && rm -rf /var/lib/apt/lists/*


COPY .${WORKDIR} ${WORKDIR}
COPY ./mxl /mxl

ENV LD_LIBRARY_PATH=/mxl/app:/mxl/ndi/lib

WORKDIR ${WORKDIR}

RUN mkdir -p ${WORKDIR}/logs

ENTRYPOINT ["/app/mxl2ndi_sink"]

ENV CATENA_PORT=6254