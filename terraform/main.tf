provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr  # Utilisation de la variable pour le CIDR
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg-${var.cluster_name}"
  description = "Security group for EKS cluster ${var.cluster_name}"
  vpc_id      = var.vpc_id  # Utilisation de la variable pour l'ID du VPC

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg-${var.cluster_name}"
  }
}

resource "aws_eks_cluster" "my_cluster" {
  name     = var.cluster_name
  role_arn = var.role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}

data "aws_eks_cluster" "existing" {
  name = aws_eks_cluster.my_cluster.name
}

resource "aws_security_group_rule" "worker_port_8083" {
  type              = "ingress"
  from_port         = 8083
  to_port           = 8083
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_eks_cluster.existing.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "worker_port_30000" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 30000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_eks_cluster.existing.vpc_config[0].cluster_security_group_id
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "noeud1"
  node_role_arn   = var.role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
