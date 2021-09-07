#-------------------------------------------------------------------------------
# My Terraform 
#
# Setting variables example
#
# $ TF_VAR_access_key = 
# $ TF_VAR_secret_key = 
#
# Needed resources:
#   - EKS Control Plane VPC
#     - EKS control plane private subnet
#     - EKS control plane public subnet
#     - EKS NLB load balancer
#     - EKS external IP and address for kubectl API access
#     - EKS cluster
#     - IAM role to work with AWS EKS IAM roles
#     - EKS IAM policy 
#   - Customer (worker) VPC
#     - autoscaling group for worker nodes
#     - customer (worker) load balancer
#     - ECR private image registry
#     - IAM role to work with ECR image registry
#     - ECR IAM policy
#   - IAM user for CI/CD tasks (builder/deployer)
#   - 
# 
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
