# models/modelA/Dockerfile
# Model A’s Dockerfile, inheriting from one of the base-app stages

# Choose which base to use at build time (default: CPU)
ARG BASE_IMAGE=myregistry/app-layer:cpu-latest
FROM ${BASE_IMAGE}

WORKDIR /app

# Install model-specific dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the model implementation
COPY . ./model

# Expose port and launch the model server
EXPOSE 8080
CMD ["python", "model/serve_model.py"]
