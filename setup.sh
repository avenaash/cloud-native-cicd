#!/bin/bash

echo "🚀 Setting up Cloud Native CI/CD Platform..."

# Check prerequisites
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "Helm is required but not installed."; exit 1; }

# Start Minikube
echo "Starting Minikube..."
minikube start --memory=4096 --cpus=4

# Enable NGINX Ingress
echo "Enabling NGINX Ingress Controller..."
minikube addons enable ingress

# Install Argo CD
echo "Installing Argo CD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Install Prometheus and Grafana using Helm
echo "Installing Prometheus and Grafana..."
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s-manifests/

# Apply Argo CD application
echo "Configuring Argo CD..."
kubectl apply -f argocd/application.yaml

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Get Argo CD admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "2. Port forward Argo CD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "3. Access Argo CD at https://localhost:8080"
echo "4. Port forward Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "5. Access Grafana at http://localhost:3000 (admin/prom-operator)"
echo "6. Add host entry: echo '127.0.0.1 fastapi.local' | sudo tee -a /etc/hosts"
