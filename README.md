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
## 🚨 Troubleshooting & Triage Log

This section documents real-world issues encountered during development and their verified solutions. Use this as a first reference before opening an issue.

### 1. ArgoCD Sync Status: "Unknown"
**Symptom:** Application shows `Sync Status: Unknown` in ArgoCD UI/CLI despite valid Git configuration.
**Root Cause:** ArgoCD controller lost connection to the Git repository or failed initial manifest parsing.
**Triage Steps:**
```bash
# Force refresh application state
argocd app get fastapi-app --refresh

# Check controller logs for specific errors
kubectl logs -n argocd deployment/argocd-application-controller | grep fastapi-app
```
**Fix:** Verify SSH keys/tokens are valid, ensure repo URL is accessible from cluster, and confirm manifests exist at the specified path.

### 2. Minikube Memory Allocation Failure
**Symptom:** `minikube start` fails with `RSRC_OVER_ALLOC_MEM: Requested memory allocation 8192MB is more than system limit`.
**Root Cause:** Host machine has insufficient RAM for requested allocation (common on WSL/Linux dev machines).
**Fix:** Reduce resource requests to match available capacity:
```bash
minikube start --memory=4096 --cpus=2 --driver=docker
```
> ⚠️ **Note:** Always verify host resources with `free -h` before starting minikube.

### 3. Port Conflicts During Local Development
**Symptom:** `port-forward` fails with `bind: address already in use` on port 8080.
**Root Cause:** Docker proxy process (`docker-pr`) or another service occupies the default port.
**Triage:**
```bash
# Identify conflicting process
sudo lsof -i :8080

# Alternative: Use non-standard port
kubectl port-forward svc/argocd-server -n argocd 9090:443
```

### 4. FastAPI CrashLoopBackOff: ModuleNotFoundError
**Symptom:** Pods crash immediately with `ModuleNotFoundError: No module named 'app'` despite successful image pull.
**Root Cause:** Dockerfile CMD references `app.main:app` but project structure uses flat `main.py` without `app/` package wrapper.
**Fix:** Update Dockerfile entrypoint to match actual file structure:
```dockerfile
# BEFORE (Incorrect)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# AFTER (Correct)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```
> 💡 **Pro Tip:** After fixing Dockerfile, force Kubernetes to pull new image: `kubectl rollout restart deployment fastapi-app`

### 5. Ingress Returns 404 Despite Valid Configuration
**Symptom:** `curl http://fastapi.local/health` returns nginx 404 error.
**Root Cause:** NGINX Ingress Controller addon not enabled in minikube; ingress resource exists but no controller processes it.
**Fix:**
```bash
minikube addons enable ingress
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx
```
Verify assignment: `kubectl get ingress fastapi-ingress` should show ADDRESS populated.

### 6. Git Pull Conflict: Local Changes Overwritten
**Symptom:** `git pull origin master` aborts with `Your local changes would be overwritten by merge`.
**Root Cause:** Uncommitted local modifications (e.g., Dockerfile fix) conflict with remote updates.
**Safe Resolution Workflow:**
```bash
# Preserve local work
git stash

# Get latest remote state
git pull origin master

# Reapply local changes
git stash pop

# Resolve conflicts if any, then commit
git add . && git commit -m "Merge remote + local fixes"
```

### 7. Grafana Dashboard Import Failures
**Symptom:** Dashboard ID `17905` fails to load or shows blank panels.
**Root Causes:**
-   Prometheus data source not selected during import
-   ServiceMonitor labels don't match Prometheus scrape config
-   Network restrictions block grafana.com API calls
**Fixes:**
-   Manually select `monitoring-prometheus` datasource in import screen
-   Verify ServiceMonitor has label `release: monitoring` matching Helm release
-   Download JSON manually from grafana.com and use "Upload dashboard JSON file" option

### 8. ImagePullBackOff with Private Registry
**Symptom:** Pods stuck in `ImagePullBackOff` despite valid Docker Hub credentials.
**Root Cause:** Missing `imagePullSecrets` in deployment spec for private repositories.
**Fix:**
```bash
# Create registry secret
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=<user> \
  --docker-password=<token> \
  -n default

# Patch deployment
kubectl patch deployment fastapi-app -n default \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
```

### 9. Prometheus Not Scraping FastAPI Metrics
**Symptom:** `/targets` page shows FastAPI endpoint as DOWN or missing entirely.
**Triage Checklist:**
-   ✅ Pod annotations present: `prometheus.io/scrape: "true"`, `prometheus.io/port: "8000"`
-   ✅ `/api/metrics` endpoint returns valid Prometheus format (test via curl)
-   ✅ ServiceMonitor selector matches pod labels exactly
-   ✅ Prometheus operator has `serviceMonitorSelectorNilUsesHelmValues=false`

### 10. ArgoCD CLI "Server Address Unspecified"
**Symptom:** All `argocd` commands fail with fatal error about unspecified server.
**Root Cause:** CLI context not configured after fresh install or minikube recreation.
**Fix:**
```bash
argocd login localhost:9090 --username admin --insecure
# Enter password from: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

### 🔍 General Debugging Commands Reference

| Command | Purpose |
|---------|---------|
| `kubectl describe pod <name> -n <ns>` | Detailed pod events & conditions |
| `kubectl logs <pod> --previous` | Logs from crashed container instance |
| `argocd app get <name> -o yaml` | Full application spec & status |
| `kubectl get events -n <ns> --sort-by=.lastTimestamp` | Chronological cluster events |
| `helm list -n <ns>` | Verify Helm releases & versions |
| `minikube ssh` | Direct access to minikube VM for network debugging |

> 📌 **Best Practice:** Always check `kubectl describe pod` output FIRST when troubleshooting pod failures—it contains the most actionable error messages from kubelet, scheduler, and container runtime.
*Built by [Avenaash](https://github.com/avenaash)*
