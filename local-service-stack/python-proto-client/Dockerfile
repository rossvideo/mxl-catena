FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN chmod +x /app/download_protos.sh
RUN ./download_protos.sh
RUN mkdir -p /app/protos \
&& python -m grpc_tools.protoc -I/app --python_out=/app/protos --grpc_python_out=/app/protos /app/*.proto \
&& touch /app/protos/__init__.py
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/protos
# proto files are mounted at /protos at runtime via docker compose volume
# compile them at startup and run main.py
CMD ["python", "main.py"]