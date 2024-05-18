terraform {
  backend "s3" {
    bucket         = "liubenok-terraform-states-backend-001"
    key            = "networking/vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "liubenok-terraform-states-lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.56.0"
    }
  }
  required_version = ">= 1.0.2"
}


provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "TerminationDate" = "Permanent",
      "Environment"     = "Development",
      "Team"            = "DevOps",
      "Application"     = "Terraform Backend"
    }
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "3.7.0"
  name            = "Dev-VPC"
  cidr            = "10.10.0.0/16"
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}
