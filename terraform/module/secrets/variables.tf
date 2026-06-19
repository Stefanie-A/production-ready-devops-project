variable "metrics_api_key" { sensitive = true }
variable "github_username" { type = string }
variable "github_pat" {
  type      = string
  sensitive = true
}
variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider" {
  type        = string
  description = "EKS OIDC provider URL (without https://)"
}