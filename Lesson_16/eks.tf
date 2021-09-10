# Cluster provisioning
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.aws_eks_cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets # worker nodes should be deployed in private subnets
  enable_irsa     = true                       # to enable the OIDC provider for this eks cluster, you just need to add the following input 

  tags = merge(var.common_tags,
    {
      GithubRepo = "terraform-aws-eks"
      GithubOrg  = "terraform-aws-modules"
    }
  )


  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      asg_desired_capacity          = 3
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }
  ]
}

data "aws_eks_cluster" "test_cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "test_cluster" {
  name = module.eks.cluster_id
}

# Security groups definitions copied from Hashicorp's tutorial
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

# Cluster access
provider "kubernetes" {
  alias                  = "eks" # to refer to it later
  host                   = data.aws_eks_cluster.test_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.test_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.test_cluster.token
  load_config_file       = false
}
