module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"
}



module "cicd_deploy_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name        = "${var.project_name}-${var.environment}-cicd-deploy-policy"
  description = "Allows GitHub Actions to deploy to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EKSAccess"
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

module "github_oidc_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name = "${var.project_name}-${var.environment}-cicd-deploy-role"

  subjects = ["repo:${var.github_repo}:*"]

  policies = {
    EKSAccess = module.cicd_deploy_policy.arn
  }
}