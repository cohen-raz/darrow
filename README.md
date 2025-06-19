# MLOps Infrastructure & Stack

**Note:** In a real-world setup, each subdirectory under `repositories/` represents a separate Git repository.

For convenience, all HLD diagrams are located under the `HLD/` directory and all implementation repositories are under the `repositories/` directory.

Below is a detailed explanation of the stack and infrastructure. In the HLD you can find images of the detailed infra architecture.

## Overview - cluster overview & layer1
- **Single Gateway**  
  A `gateway-service` (Flask) exposed via Ingress/LoadBalancer handles all external client requests. It validates input, writes each request into PostgreSQL, and publishes an `inference_request` event (with an `action` field) to our pub/sub bus.

- **Pub/Sub & Model Services**  
  Inference requests are published to a single AWS SNS topic with an `action` attribute. Each `modelX-service` Deployment polls its own SQS queue—subscribed to the SNS topic with a filter policy on `action`—so it only receives relevant messages. Upon receiving a message, a model:
  1. Executes `predict(text)`
  2. Saves intermediate feature outputs to S3   
  3. Emits its unified output back to the gateway (publish `inference_response` event)
  4. Returns the response to the gateway   
  
- **Ml Gateway**  
  The `gateway-service` receives the model output, writes it back to PostgreSQL, and publishes an `job completed` event to the pub/sub bus.
- **Primary Database**  
  A PostgreSQL StatefulSet in the `infra` namespace is our single source of truth for all requests, predictions, human labels, and aggregated metrics.

- **ML-Specific Monitoring**  
  A standalone **Monitoring Service** (Kubernetes CronJob) connects to PostgreSQL hourly to:
  1. Pull recent predictions and any ground-truth labels (from Label Studio)  
  2. Run drift and performance reports via the Evidently AI library  
  3. Persist roll-up metrics (accuracy, F1, confidence distribution, drift scores) back into PostgreSQL or expose them 

- **Human-in-the-Loop Annotation**  
  **Label Studio** runs in its own `annotation` namespace. Annotators fetch un-labeled model outputs from PostgreSQL, tag the true labels, and write them back—closing the feedback loop for live quality evaluation.

- **Real-Time App Observability**  
  **Groundcover**’s runs as a DaemonSet on every node, capturing logs, traces, and metrics from the gateway and model containers. all visualized in an embedded Grafana UI for live debugging and alerting.

---

## Overview – Layer 2: ML Models Repository

This **mono-repo** (`ml-models`) contains all of the code and configuration needed to train, build, and serve every model in our fleet. It’s organized into two main sections:

### 1. App Layer  
- **Unified API**  
  - Defines an `AbstractModel` base class (`predict`, `train`, `eval`) that every model inherits.  
- **MLflow Integration**  
  - Uses the MLflow Client library to log experiments, register models, and retrieve the correct model version at runtime.  
- **Multi-Stage Base Dockerfile**  
  - Builds CPU and GPU variants of a “base-app” image, installing shared dependencies from `app/requirements.txt`.  
- **CI/CD Jobs** (`app/jobs/`)  
  - Shell scripts (train, eval, build-image, deploy) invoked via Jenkins (Flask CLI) or GitHub Actions/webhooks on PRs and merges.

### 2. Per-Model Directories (`models/<model_name>/`)  
Each model lives in its own folder, containing:  
- **Dockerfile**  
  - Inherits from the base-app image (CPU, GPU, or custom) via build-arg.  
- **values.yaml**  
  - Helm overrides for image tag, resource requests, autoscaling, environment variables, etc.  
- **Implementation**  
  - Subclass of `AbstractModel` implementing `predict(text)`, `train()`, and `eval()`.  
- **Data I/O**  
  - Saves intermediate features or artifacts to S3 and logs training/eval metrics back to MLflow.

### Workflow Summary

1. **Add a New Model**  
   - Create `models/my-model/`, implement the base-class methods, define `requirements.txt`, `Dockerfile`, and `values.yaml`.  
2. **CI/CD**  
   - **Base Image**: `Dockerfile.app` is built (CPU/GPU) and pushed.  
   - **Model Image**: Built from the base, tagged, and pushed on PR/merge.  
   - **Deploy**: Helm uses the model’s `values.yaml` to deploy into its own namespace; the container fetches the proper model artifact from MLflow Model Registry.  
3. **Inference**  
   - Every model service exposes the same `predict(text)` endpoint, writing results (and confidence) back into PostgreSQL and returning unified output to the gateway.

This design lets any data scientist onboard a new model with just a few files, while reusing the same API, Docker base, CI/CD jobs, and deployment infrastructure.  


