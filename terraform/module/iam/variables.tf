variable "github_repo" {
  description = "GitHub repo in format owner/repo-name"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}