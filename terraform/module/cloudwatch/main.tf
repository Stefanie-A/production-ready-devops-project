module "log_group_app" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 5.0"

  name              = "/aws/eks/${var.cluster_name}/${var.project_name}/app"
  retention_in_days = 30
  tags              = { Name = "${var.project_name}-${var.environment}-app-logs" }
}

module "log_group_controlplane" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 5.0"

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
  tags              = { Name = "${var.project_name}-${var.environment}-controlplane-logs" }
}

module "alarm_cpu" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 5.0"

  alarm_name          = "${var.project_name}-${var.environment}-node-cpu-high"
  alarm_description   = "EKS node CPU above 80% for 10 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  dimensions          = { ClusterName = var.cluster_name }
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

module "alarm_memory" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 5.0"

  alarm_name          = "${var.project_name}-${var.environment}-node-memory-high"
  alarm_description   = "EKS node memory above 80% for 10 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  dimensions          = { ClusterName = var.cluster_name }
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

module "alarm_pod_restarts" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 5.0"

  alarm_name          = "${var.project_name}-${var.environment}-pod-restarts-high"
  alarm_description   = "Pod restarts exceeded 5 in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  dimensions          = { ClusterName = var.cluster_name }
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns_topic && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}