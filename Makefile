TF_DIR := terraform

up:
	kind create cluster --name my-cluster

down:
	kind delete cluster --name my-cluster

init:
	cd $(TF_DIR) && terraform init

validate:
	cd $(TF_DIR) && terraform validate

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply -auto-approve

destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve