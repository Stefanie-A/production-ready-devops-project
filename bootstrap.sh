#!/bin/bash
# -----------------------------------------------------------------------------
# local_setup.sh
#
# Purpose:    Automates the setup of a local Kubernetes cluster using kind and aws eks,
#             configures namespaces, secrets, and installs Helm charts for
#             Prometheus and Argo CD.
#
# Usage:      export GHCR_TOKEN=your_token_here
#             ./bootstrap.sh
#
# Prereqs:    - kind installed and in PATH
#             - kubectl installed and in PATH
#             - helm installed and in PATH
#             - GHCR_TOKEN environment variable set
# -----------------------------------------------------------------------------
set -euo pipefail

CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name)
REGION=$(cd terraform && terraform output -raw region)


# if [[ -z "${GIT_TOKEN:-}" ]]; then
#   echo "ERROR: GIT_TOKEN is not set. Export it before running ./bootstrap.sh."
#   echo "Example: export GIT_TOKEN=your_token_here"
#   exit 1
# fi

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  echo "ERROR: SLACK_WEBHOOK_URL is not set. Export it before running ./bootstrap.sh."
  echo "Example: export SLACK_WEBHOOK_URL=your_webhook_url_here"
  exit 1
fi

# if [[ -z "${METRICS_KEY:-}" ]]; then
#   echo "WARNING: Metrics_api_key is not set. Using default value 'default-metrics-key'."
# fi

# if ! command -v kind &> /dev/null; then
#   echo "ERROR: 'kind' is not installed or not found in PATH. Please install kind before running this script."
#   exit 1
# fi

if ! aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"; then
  echo "ERROR: Failed to update kubeconfig for cluster '$CLUSTER_NAME' in region '$REGION'."
  echo "Make sure the cluster exists and your AWS credentials are configured correctly."
  exit 1
fi

for ns in app monitoring argocd falco external-secrets; do
  if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
    kubectl create namespace "$ns"
  fi
done

# kubectl get secret ghcr-secret -n app >/dev/null 2>&1 || kubectl create secret docker-registry ghcr-secret \
#   --docker-server=ghcr.io \
#   --docker-username=stefanie-a \
#   --docker-password="$GIT_TOKEN" \
#   --docker-email=albertstephanie630@gmail.com \
#   -n app

# kubectl get secret metrics-secret -n monitoring >/dev/null 2>&1 || kubectl create secret generic metrics-secret \
#   --from-literal=api-key="$METRICS_KEY" \
#   --namespace monitoring

# For EKS
if ! helm status external-secrets -n external-secrets >/dev/null 2>&1; then
  helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace external-secrets \
    --wait \
    --timeout 120s \
    --set serviceAccount.name=external-secrets-sa \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$(cd terraform && terraform output -raw eso_role_arn)"
fi

helm repo update

if ! helm status prometheus -n monitoring >/dev/null 2>&1; then
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring
fi

if ! helm status argo -n argocd >/dev/null 2>&1; then
  helm upgrade --install argo argo/argo-cd \
    --namespace argocd \
    --set crds.install=true
  kubectl wait --for=condition=Established --timeout=120s crd/applications.argoproj.io >/dev/null 2>&1
fi

if ! helm status argocd-image-updater -n argocd >/dev/null 2>&1; then
  helm upgrade --install argocd-image-updater argo/argocd-image-updater \
    --namespace argocd 
fi

if ! helm status falco -n falco >/dev/null 2>&1; then
  helm upgrade --install falco falcosecurity/falco \
    --namespace falco \
    --set tty=true \
    --set falcosidekick.enabled=true \
    --set falcosidekick.webui.enabled=true \
    --set falcosidekick.config.slack.webhookurl="$SLACK_WEBHOOK_URL" \
    --set falcosidekick.config.slack.minimumpriority=warning \
    --set-file customRules."custom-rules\.yaml"=k8s/falco-custom-rules.yaml
fi

if [ -d "k8s/manifests" ]; then
  echo "Waiting for External Secrets CRDs to be established..."
  kubectl wait --for=condition=Established --timeout=120s \
    crd/clustersecretstores.external-secrets.io \
    crd/externalsecrets.external-secrets.io

  echo "Waiting for ESO deployment to be ready..."
  kubectl wait --for=condition=available --timeout=120s \
    deployment/external-secrets -n external-secrets

  echo "Giving API server time to register CRDs..."
  sleep 30

  echo "Applying ClusterSecretStore..."
  kubectl apply -f k8s/secret-store.yaml

  echo "Applying ExternalSecrets..."
  kubectl apply -f k8s/external-secrets.yaml

  echo "Waiting for ExternalSecrets to sync..."
  sleep 15

  kubectl wait --for=condition=Established --timeout=120s \
    crd/applications.argoproj.io >/dev/null 2>&1

  if ! helm status manifests -n app >/dev/null 2>&1; then
    helm install manifests k8s/manifests \
      --namespace app
  fi
else
  echo "ERROR: Directory 'k8s/manifests' does not exist. Please ensure the Helm chart directory is present."
  exit 1
fi
echo "✅ Bootstrap complete"