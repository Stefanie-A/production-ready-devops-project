module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true  

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true
  
  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]

      min_size     = var.node_min
      max_size     = var.node_max
      desired_size = var.node_desired

      labels = {
        role = "worker"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "todo-api"
  }
}
