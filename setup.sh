# #!/bin/bash

# aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)

# Create the pull secret
# kubectl create namespace app
# kubectl create secret docker-registry ghcr-pull-secret \
#   --docker-server=ghcr.io \
#   --docker-username=stefanie-a \
#   --docker-password=<your-github-pat> \
#   --docker-email=<your-email> \
#   -n app

# Patch the deployment
# kubectl patch deployment todo-api-deployment -n app \
#   -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ghcr-pull-secret"}]}}}}'


kubectl create secret docker-registry ghcr-secret --docker-server=ghcr.io --docker-username=stefanie-a --docker-password=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 --docker-email=albertstephanie630@gmail.com -n app