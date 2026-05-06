variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "todo-eks-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "node_min" {
  type    = number
  default = 1
}

variable "node_max" {
  type    = number
  default = 5
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "todo-api"
}

variable "environment" {
  description = "Environment name for tagging (e.g., dev, staging, prod)"
  type        = string
  default     = "production"
  
}

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for alerts"
  type        = bool
  default     = true
}

variable "github_repo" {
  description = "GitHub repository in the format owner/repo-name"
  type        = string
  default     = "Stefanie/production-ready-devops-project"
}