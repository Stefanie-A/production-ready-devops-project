TF_DIR := terraform

up:
	kind create cluster --name my-cluster

clean:
	kind delete cluster --name my-cluster

tf_plan:
	cd $(TF_DIR) && terraform plan

tf_up:
	cd $(TF_DIR) && terraform apply auto-approve

tf_down:
	cd $(TF_DIR) && terraform destroy auto-approve