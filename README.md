***

# ☁️ Cloud-Native CI/CD: FastAPI + GitHub Actions + ArgoCD + Monitoring

A complete end-to-end cloud-native pipeline demonstrating modern DevOps practices. This project automates the build, test, deploy, and monitoring lifecycle of a Python FastAPI application using **GitHub Actions**, **ArgoCD (GitOps)**, and **Prometheus/Grafana**.

## 🏗️ Architecture Overview

```mermaid
graph LR
    A[Developer] -->|Push Code| B(GitHub Repo)
    B -->|Trigger| [GitHub Actions]
    C -->|Build & Test| D[Docker Image]
    D -->|Push| E[Docker Hub]
    B -->|Sync Manifests| F[ArgoCD]
    F -->|Pull Image| E
    F -->|Deploy| G[Kubernetes / Minikube]
    G -->|Expose Metrics| H[Prometheus]
    H -->|Visualize| I[Grafana]
```

## 🚀 Key Features

-   **Application**: High-performance REST API built with **FastAPI** and Uvicorn.
-   **CI Pipeline**: Automated testing and Docker image building via **GitHub Actions**.
-   **GitOps CD**: Declarative deployment management using **ArgoCD**.
-   **Observability**: Full-stack monitoring with **Prometheus** and **Grafana**.
-   **Auto-Scaling**: Horizontal Pod Autoscaler (HPA) configured for traffic spikes.
-   **Ingress**: NGINX Ingress Controller for external access and routing.

## 📂 Project Structure

```text
cloud-native-cicd/
├── .github/workflows/      # CI/CD Pipeline Definitions
│   └── cd.yaml             # Build, Push, and Notify workflow
├── argocd/                 # ArgoCD Application Manifests
│   └── application.yaml    # GitOps sync configuration
├── k8-manifests/           # Kubernetes Deployment Resources
│   ├── deployment.yaml     # App deployment & env vars
│   ├── service.yaml        # ClusterIP service
│   ├── ingress.yaml        # NGINX ingress rules
│   └── hpa.yaml            # Auto-scaling policy
├── monitoring/             # Observability Stack
│   └── servicemonitor.yaml # Prometheus scraping config
├── tests/                  # Pytest Unit Tests
├── Dockerfile              # Multi-stage container build
├── main.py                 # FastAPI Application Entry Point
└── requirements.txt        # Python Dependencies
```

## 🛠️ Tech Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Language** | Python 3.11 | Backend Logic |
| **Framework** | FastAPI + Uvicorn | Async Web Server |
| **Container** | Docker | Application Packaging |
| **Registry** | Docker Hub | Image Storage |
| **Orchestrator** | Kubernetes (Minikube) | Container Management |
| **CI** | GitHub Actions | Automated Testing & Build |
| **CD** | ArgoCD | GitOps Synchronization |
| **Monitoring** | Prometheus + Grafana | Metrics & Visualization |
| **Ingress** | NGINX | External Traffic Routing |

## ⚡ Quick Start Guide

### Prerequisites
-   Docker Desktop / Docker Engine
-   Minikube (`minikube start --memory=4096 --cpus=2`)
-   Kubectl & Helm
-   ArgoCD CLI (Optional)

### 1. Setup Local Environment
```bash
# Clone the repository
git clone https://github.com/avenaash/cloud-native-cicd.git
cd cloud-native-cicd

# Start Minikube with sufficient resources
minikube start --memory=4096 --cpus=2 --driver=docker

# Enable NGINX Ingress
minikube addons enable ingress
```

### 2. Deploy ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
watch kubectl get pods -n argocd

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Deploy the Application
```bash
# Apply the ArgoCD Application manifest
kubectl apply -f argocd/application.yaml

# Force sync if needed
argocd app sync fastapi-app --force
```

### 4. Deploy Monitoring Stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin123

# Import Dashboard ID: 17905 in Grafana for FastAPI metrics
```

##  Monitoring & Observability

### Access Points
| Service | URL / Command | Credentials |
| :--- | :--- | :--- |
| **ArgoCD UI** | `http://localhost:8080` | admin / `<secret>` |
| **Grafana** | `kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80` | admin / admin123 |
| **Prometheus** | `kubectl port-forward svc/prometheus-operated -n monitoring 9090:9090` | N/A |
| **FastAPI App** | `minikube service fastapi-service --url` | N/A |

### Key Metrics Tracked
-   **HTTP Requests**: Total count, latency (p50, p95, p99), status codes.
-   **System Resources**: CPU/Memory usage per pod.
-   **Application Health**: Liveness/Readiness probe status.
-   **Cluster State**: Node capacity, pod restarts, HPA scaling events.

## 🔄 CI/CD Workflow Details

1.  **Code Push**: Developer pushes to `master` branch.
2.  **GitHub Actions**:
    -   Runs `pytest` on `tests/`.
    -   Builds Docker image tagged with commit SHA.
    -   Pushes image to Docker Hub (`avenaashrs/fastapi-app`).
3.  **ArgoCD Sync**:
    -   Detects new commit in Git repo.
    -   Compares live cluster state vs. desired Git state.
    -   Automatically applies changes to Kubernetes.
4.  **Health Check**: ArgoCD verifies pod health and updates sync status.

## 🐛 Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **CrashLoopBackOff** | Check logs: `kubectl logs <pod>`. Verify `CMD` in Dockerfile matches entrypoint. |
| **ImagePullBackOff** | Ensure image exists on Docker Hub. Check `imagePullSecrets` if private. |
| **ArgoCD Unknown** | Run `argocd app get <app> --refresh`. Check repo connectivity. |
| **Ingress 404** | Verify `minikube addons enable ingress` ran successfully. Check host rules. |
| **No Metrics** | Ensure `/api/metrics` endpoint returns data. Check ServiceMonitor labels match Prometheus config. |

##  Contributing

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.
---
*Built by [Avenaash](https://github.com/avenaash)*
