# Data resource to fetch the default VPC
data "aws_vpc" "BankApp_VPC" {
  filter {
    name   = "tag:Name"
    values = ["BankApp_VPC"]
  }
}
# Data resource to fetch subnets within the VPC
data "aws_subnets" "master_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.BankApp_VPC.id]
  }
}
# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}
# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "bankApp" {
  name     = "bankApp"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = data.aws_subnets.master_subnets.ids
    endpoint_public_access = true
  }

  # Specify the Kubernetes version
  version = "1.30"

  tags = {
    Name = "bankApp"
  }
}
# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies for Node Group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}
# EKS Node Group
resource "aws_eks_node_group" "bankApp_nodegroup" {
  cluster_name    = aws_eks_cluster.bankApp.name
  node_group_name = "bankApp"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.master_subnets.ids

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  instance_types = ["t2.medium"]
  disk_size      = 29

  remote_access {
    ec2_ssh_key = "eks-nodegroup-key"
  }

  tags = {
    Name = "bankApp-nodegroup"
  }
}
