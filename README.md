# Production Ready DevOps Project

This project came out of a DevOps practical challenge — the goal was to take a simple API and build everything around it that you'd expect in a real production environment. That means proper infrastructure, a real CI/CD pipeline, security scanning, and monitoring.

## What's in here

The app itself is a Todo API built with FastAPI and Python. Nothing fancy — it's intentionally simple because the point of the project is everything around it, not the app itself.

The infrastructure is all on AWS, provisioned with Terraform. The code is split into modules for the VPC, EKS cluster, IAM, and CloudWatch so each piece can be understood and changed independently. The app runs on EKS with a managed node group that scales between 1 and 4 nodes depending on load.

The CI/CD pipeline runs on GitHub Actions. When you push to main, it scans for secrets, runs SAST on the Python code, runs the test suite, builds and scans the Docker image for vulnerabilities, applies any infrastructure changes, deploys to the cluster, and commits the new image tag back to the repo. Pull requests get a Terraform plan posted as a comment so you can see what will change before it does. Authentication to AWS is done via OIDC — no long-lived credentials stored anywhere.

## Running locally

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API docs will be at `http://localhost:8000/docs`.

```bash
# Run tests
pytest tests/ -v

# Or with Docker
docker compose up --build
```

## Deploying the infrastructure

You'll need the AWS CLI, Terraform, and kubectl installed.

```bash
cd terraform
terraform init
terraform plan
terraform apply

# Point kubectl at the new cluster
aws eks update-kubeconfig --region us-east-1 --name todo-app-prod-cluster
```
## Setting up Prometheus and Grafana

Both are installed into the cluster using the kube-prometheus-stack Helm chart, which bundles everything you need.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

Once running, access Grafana locally:

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

Then open `http://localhost:3000` — default login is `admin / prom-operator`.

Prometheus is available at:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
```



## GitHub secrets needed

Two secrets need to be set in the repo before the pipeline will work:

- `AWS_DEPLOY_ROLE_ARN` — get this from `terraform output cicd_deploy_role_arn` after applying
- `PAT_TOKEN` — a personal access token with `repo` scope, used to commit the updated image tag back to the repo