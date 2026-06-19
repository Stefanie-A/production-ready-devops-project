resource "aws_secretsmanager_secret" "github" {
  name = "todo-api/github-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "github" {
  secret_id = aws_secretsmanager_secret.github.id
  secret_string = jsonencode({
    username = var.github_username
    password = var.github_pat
  })
}

resource "aws_secretsmanager_secret" "metrics" {
  name = "todo-api/metrics-api-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "metrics" {
  secret_id     = aws_secretsmanager_secret.metrics.id
  secret_string = jsonencode({ api-key = var.metrics_api_key })
}

data "aws_iam_policy_document" "eso_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets-sa"]
    }
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.eso_assume.json
}

resource "aws_iam_policy" "eso_secrets_read" {
  name = "eso-secrets-read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [
        aws_secretsmanager_secret.github.arn,
        aws_secretsmanager_secret.metrics.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eso_attach" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso_secrets_read.arn
}