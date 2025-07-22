#!/bin/bash

set -e

echo "Installing Kubernetes Startup Components..."

echo "Step 1: Installing Kubernetes Gateway API..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

echo "Step 2: Adding Argo Helm repository..."
if ! helm repo list | grep -q argo; then
    helm repo add argo https://argoproj.github.io/argo-helm
    echo "Argo Helm repository added."
else
    echo "Argo Helm repository already exists."
fi

echo "Step 3: Updating Helm repositories..."
helm repo update

echo "Step 4: Installing ArgoCD..."
helm install yke-argo-cd argo/argo-cd --version 8.1.2 --namespace argocd --create-namespace

echo "Installation completed successfully!"
echo "You can access ArgoCD by port-forwarding: kubectl port-forward svc/yke-argo-cd-argocd-server -n argocd 8080:443"
echo "Default username: admin"
echo "Get the password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
