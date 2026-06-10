#!/bin/bash
# -----------------------------------------------------------------------------
# local_setup.sh
#
# Purpose:    Automates the setup of a local Kubernetes cluster using kind and aws eks,
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

if [[ -z "${GIT_TOKEN:-}" ]]; then
  echo "ERROR: GIT_TOKEN is not set. Export it before running ./local_setup.sh."
  echo "Example: export GIT_TOKEN=your_token_here"
  exit 1
fi

if ! command -v kind &> /dev/null; then
  echo "ERROR: 'kind' is not installed or not found in PATH. Please install kind before running this script."
  exit 1
fi

# aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)


for ns in app monitoring argocd falco; do
  if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
    kubectl create namespace "$ns"
  fi
 done

kubectl get secret ghcr-secret -n app >/dev/null 2>&1 || kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=stefanie-a \
  --docker-password="$GIT_TOKEN" \
  --docker-email=albertstephanie630@gmail.com \
  -n app

kubectl get secret metrics-secret -n monitoring >/dev/null 2>&1 || kubectl create secret generic metrics-secret \
  --from-literal=api-key=default-metrics-key \
  --namespace monitoring

helm repo update

if ! helm status prometheus -n monitoring >/dev/null 2>&1; then
  helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring
fi

if ! helm status argo -n argocd >/dev/null 2>&1; then
  helm install argo argo/argo-cd \
    --namespace argocd \
    --set crds.install=true
  kubectl wait --for=condition=Established --timeout=120s crd/applications.argoproj.io >/dev/null 2>&1
fi

if ! helm status falco -n falco >/dev/null 2>&1; then
  helm install falco falcosecurity/falco \
    --namespace falco \
    --set tty=true
fi

if [ -d "k8s/manifests" ]; then
  kubectl wait --for=condition=Established --timeout=120s crd/applications.argoproj.io >/dev/null 2>&1
  if ! helm status manifests -n app >/dev/null 2>&1; then
    helm install manifests k8s/manifests \
      --namespace app
  fi
else
  echo "ERROR: Directory 'k8s/manifests' does not exist. Please ensure the Helm chart directory is present."
  exit 1
fi