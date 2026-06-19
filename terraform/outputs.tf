output "cluster_name"     { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "vpc_id"           { value = module.vpc.vpc_id }
output "eso_role_arn" { value = module.secrets.eso_role_arn }
# output "metrics_secret_arn" {
#   value = aws_secretsmanager_secret.metrics.arn
# }
output "region" { value = var.region }