terraform {
  backend "s3" {
    bucket         = "liubenok-terraform-states-backend-001"
    key            = "infrastructure-by-single-command/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "liubenok-terraform-states-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.default_tags
  }
}

locals {
  cluster_name = "${var.deployment_prefix}-vlad-eks-cluster"
  cluster_users = try([
    for arn in var.cluster_users :
    {
      userarn  = arn
      username = regex("[a-zA-Z0-9-_]+$", arn)
      groups = [
        "system:masters"
      ]
    }
  ], [])
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "19.5.1"
  cluster_name                    = local.cluster_name
  cluster_version                 = "1.29"
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  enable_irsa                     = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  aws_auth_users = concat(
  local.cluster_users)
  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = []

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  tags = {
    "Name"            = "${local.cluster_name}"
    "Type"            = "Kubernetes Service"
    "K8s Description" = "Kubernetes for deployment related to ${var.deployment_prefix}"
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    management = {
      min_size     = 2
      max_size     = 5
      desired_size = 2

      instance_types = ["t3.xlarge"]
      capacity_type  = "ON_DEMAND"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 70
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      labels = {
        "node.k8s/role" = "management"
      }
    }
  }

  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      source_cluster_security_group = true
      description                   = "Allow workers pods to receive communication from the cluster control plane."
    }
    ingress_self_all = {
      description = "Allow nodes to communicate with each other (all ports/protocols)."
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress."
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

