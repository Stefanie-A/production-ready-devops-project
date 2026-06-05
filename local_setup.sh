#!/bin/bash
# -----------------------------------------------------------------------------
# local_setup.sh
#
# Purpose:    Automates the setup of a local Kubernetes cluster using kind,
#             configures namespaces, secrets, and installs Helm charts for
#             Prometheus and Argo CD.
#
# Usage:      export GHCR_TOKEN=your_token_here
#             ./local_setup.sh
#
# Prereqs:    - kind installed and in PATH
#             - kubectl installed and in PATH
#             - helm installed and in PATH
#             - GHCR_TOKEN environment variable set
# -----------------------------------------------------------------------------
set -euo pipefail

if [[ -z "${GHCR_TOKEN:-}" ]]; then
  echo "ERROR: GHCR_TOKEN is not set. Export it before running ./local_setup.sh."
  echo "Example: export GHCR_TOKEN=your_token_here"
  exit 1
fi

if ! command -v kind &> /dev/null; then
  echo "ERROR: 'kind' is not installed or not found in PATH. Please install kind before running this script."
kubectl get namespace app || kubectl create namespace app
fi

kind create cluster --name my-cluster

kubectl create namespace app
kubectl create namespace monitoring
kubectl create namespace argocd

kubectl get secret ghcr-secret -n app >/dev/null 2>&1 || kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=stefanie-a \
  --docker-password="$GHCR_TOKEN" \
  --docker-email=albertstephanie630@gmail.com \
  -n app

kubectl create secret generic metrics-secret \
  --from-literal=api-key=default-metrics-key \
  --namespace monitoring

helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring

helm install argo argo/argo-cd \
  --namespace argocd

if [ -d "k8s/manifests" ]; then
  helm install manifests k8s/manifests \
    --namespace app
else
  echo "ERROR: Directory 'k8s/manifests' does not exist. Please ensure the Helm chart directory is present."
  exit 1
fi