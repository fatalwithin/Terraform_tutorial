# IAM Role to be granted ECR permissions
resource "aws_iam_role" "ecr" {
  name = "ecr"
}

# AWS ECR Repository 
resource "aws_ecr_repository" "test" {
  name                 = var.aws_ecr_repository_name
  image_tag_mutability = "IMMUTABLE"

  /*
Repositories configured with immutable tags will prevent image tags from being overwritten. For more information, see Image tag mutability.
  */

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Environment"]} ECR repository build by Terraform" })
}

data "aws_ecr_authorization_token" "test" {
  registry_id = aws_ecr_repository.test.registry_id
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

