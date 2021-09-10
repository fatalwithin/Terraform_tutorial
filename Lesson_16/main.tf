#-------------------------------------------------------------------------------
# My Terraform 
#
# Setting variables example
#
# $ TF_VAR_access_key = 
# $ TF_VAR_secret_key = 
#
# The order of infra resources creation:
#   - ECR image registry
#   - VPC resources for EKS cluster via vpc terrafoerm module
#   - EKS cluster - 2 or 3 small workers in order to keep costs low (although EKS costs $0.1 per cluster )
#   - OpenID connect provider for EKS cluster for ALB Ingress Controller to work
#   - OIDC IAM role for 
#-------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.57.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Credential resources
resource "random_password" "ecr_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_ssm_parameter" "ecr_password" {
  name        = "/dev/ecr"
  description = "password for accessing AWS ECR repository "
  type        = "SecureString"
  value       = random_password.ecr_password.result
}

data "aws_ssm_parameter" "my_ecr_password" {
  name       = "/dev/ecr"
  depends_on = [aws_ssm_parameter.ecr_password]
}
