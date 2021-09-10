data "aws_region" "current" {}

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = data.aws_eks_cluster.test_cluster.name
}

module "alb_ingress_controller" {
  source  = "iplabs/alb-ingress-controller/kubernetes"
  version = "3.4.0"

  providers = {
    kubernetes = "kubernetes.eks"
  }

  # If k8s_cluster_type set to `eks`, the Kubernetes cluster will be assumed to be run on EKS which will make sure that the AWS IAM Service integration works as supposed to.
  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"
  k8s_cluster_name = data.aws_eks_cluster.test_cluster.name
}
