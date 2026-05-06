variable "project_name" { type = string }
variable "environment"  { type = string }
variable "cluster_name" { type = string }

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN for alarm notifications. Leave empty to skip."
  type        = string
  default     = ""
}

variable "create_sns_topic" {
  description = "Set to true to create a new SNS topic for alarm notifications"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address to receive alarm notifications"
  type        = string
  default     = ""
}