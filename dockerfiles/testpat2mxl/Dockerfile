# Minimal container for the test_bars service
FROM ubuntu:24.04

COPY ./mxl /mxl
COPY ./update_flow_id.py /usr/local/bin/update_flow_id.py
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /mxl/app

ENV LD_LIBRARY_PATH=/mxl/app:/mxl/ndi/lib
ENV PATH=/mxl/app:$PATH

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libstdc++6 \
		libgstreamer1.0-0 \
		libgstreamer-plugins-base1.0-0 \
		gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
		gstreamer1.0-tools \
		gstreamer1.0-x \
		python3 \
	&& rm -rf /var/lib/apt/lists/*

RUN chmod +x /usr/local/bin/entrypoint.sh

# Execute mxl-info directly; pass args via compose `command`.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
