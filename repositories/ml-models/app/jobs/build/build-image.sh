#!/usr/bin/env bash
set -euo pipefail

# Usage: build-image.sh <model_name> <image_tag>
MODEL="$1"
TAG="$2"
REGISTRY="${ECR_REGISTRY:-myregistry}"   # set via env or fallback

echo "Building Docker image for ${MODEL}:${TAG}..."
docker build \
  --file models/"${MODEL}"/Dockerfile \
  --tag "${REGISTRY}/${MODEL}:${TAG}" \
  .

echo "Pushing to ${REGISTRY}/${MODEL}:${TAG}..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"
docker push "${REGISTRY}/${MODEL}:${TAG}"

echo "Build & push complete."
