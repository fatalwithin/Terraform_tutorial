#-------------------------------------------------------------------------------
# My Terraform 
#
# Password generation
# SSM Parameter Store usage
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

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# IAM Role to be granted ECR permissions
data "aws_iam_role" "ecr" {
  name = "ecr"
}

# Network and organizational resources
resource "aws_vpc" "test_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = merge(var.common_tags, { Name = "${var.common_tags["Environment"]} VPC built by Terraform" })
}

data "aws_vpc" "test_vpc" {
  id = aws_vpc.test_vpc.id
}

resource "aws_subnet" "test-subnet-01" {
  vpc_id     = data.aws_vpc.test_vpc.id
  cidr_block = "192.168.0.0/24"

  tags = merge(var.common_tags, { Name = "${var.common_tags["Environment"]} VPC Subnet built by Terraform" })
}

resource "aws_subnet" "test-subnet-02" {
  vpc_id     = data.aws_vpc.test_vpc.id
  cidr_block = "192.168.0.1/24"

  tags = merge(var.common_tags, { Name = "${var.common_tags["Environment"]} VPC Subnet built by Terraform" })
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



# AWS ECR Repository 
resource "aws_ecr_repository" "test" {
  name                 = "test"
  image_tag_mutability = "IMMUTABLE"

  /*
Repositories configured with immutable tags will prevent image tags from being overwritten. For more information, see Image tag mutability.
  */

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Environment"]} ECR repository build by Terraform" })
}

data "aws_ecr_repository" "test" {
  name = "test"
}

data "aws_ecr_authorization_token" "test" {
  registry_id = aws_ecr_repository.test.id
}

/*
To authenticate Docker to an Amazon ECR private registry with get-login-password
To authenticate Docker to an Amazon ECR registry with get-login-password, run the aws ecr
get-login-password command. When passing the authentication token to the docker login command,
use the value AWS for the username and specify the Amazon ECR registry URI you want to
authenticate to. If authenticating to multiple registries, you must repeat the command for each
registry.

$ aws ecr get-login-password --region region | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com

*/

resource "aws_ecr_repository_policy" "testpolicy" {
  repository = aws_ecr_repository.test.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Allows full ECR access to the test repository",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

# IAM user for CI/CD tasks
resource "aws_iam_user" "publisher" {
  name = "ecr-publisher"
}

resource "aws_iam_access_key" "publisher" {
  user = aws_iam_user.publisher.name
}

