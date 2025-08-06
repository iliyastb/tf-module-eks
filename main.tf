resource "aws_eks_cluster" "eks" {
  name     = "${var.env}-eks-cluster"
  role_arn = aws_iam_role.eks-cluster-role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "node-group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "tf-nodes-spot"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "SPOT"
  instance_types  = ["t3.xlarge"]

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy-attach,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy-attach,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly-attach,
  ]
}

data "external" "thumb" {
  program = ["kubergrunt", "eks", "oidc-thumbprint", "--issuer-url", aws_eks_cluster.eks.identity.0.oidc.0.issuer]
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumb.result.thumbprint]
  url             = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}