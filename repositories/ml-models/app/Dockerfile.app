# Dockerfile.app
# Multi-stage build for shared “app” layer: CPU and GPU variants

# ---- CPU base image ----
FROM python:3.9-slim AS cpu-app

WORKDIR /app
# Copy shared application code and install CPU dependencies
COPY app/requirements.txt .
COPY app/ ./app
RUN pip install --no-cache-dir -r requirements.txt

# ---- GPU base image ----
FROM nvidia/cuda:11.6-cudnn8-runtime AS gpu-app

WORKDIR /app
# Copy shared application code and install GPU dependencies
COPY app/requirements-gpu.txt .
COPY app/ ./app
RUN pip install --no-cache-dir -r requirements-gpu.txt
