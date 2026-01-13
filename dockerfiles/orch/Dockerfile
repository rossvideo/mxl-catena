FROM python:3.14-slim

WORKDIR /app
RUN python -m venv .venv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
