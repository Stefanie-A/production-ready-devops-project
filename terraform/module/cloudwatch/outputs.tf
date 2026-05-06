output "app_log_group_name" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "controlplane_log_group_name" {
  description = "CloudWatch log group for EKS control plane logs"
  value       = aws_cloudwatch_log_group.eks_controlplane.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts (empty if not created)"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : ""
}