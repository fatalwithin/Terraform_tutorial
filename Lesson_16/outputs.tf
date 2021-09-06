# ECR outputs
output "ecr_name" {
  value = data.aws_ecr_repository.test.name
}

output "ecr_arn" {
  value = data.aws_ecr_repository.test.arn
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.test.repository_url
}

output "ecr_registry_id" {
  value = data.aws_ecr_repository.test.registry_id
}

# ECR auth token outputs
output "ecr_token_authorization_token" {
  value = data.aws_ecr_authorization_token.test.authorization_token
}

output "ecr_token_expires_at" {
  value = data.aws_ecr_authorization_token.test.expires_at
}

output "ecr_token_id" {
  value = data.aws_ecr_authorization_token.test.id
}

output "ecr_token_user_name" {
  value = data.aws_ecr_authorization_token.test.user_name
}

output "ecr_token_password" {
  value = data.aws_ecr_authorization_token.test.password
}

output "ecr_token_proxy_endpoint" {
  value = data.aws_ecr_authorization_token.test.proxy_endpoint
}

output "ecr_token_expires_at" {
  value = data.aws_ecr_authorization_token.test.expires_at
}

# AWS SSM outputs
output "ecr_password" {
  value = data.aws_ssm_parameter.my_ecr_password.value
}

# CI/CD account credentials
output "publisher_access_key" {
  value     = aws_iam_access_key.publisher.id
  sensitive = false
}

output "publisher_secret_key" {
  value     = aws_iam_access_key.publisher.secret
  sensitive = true
}
