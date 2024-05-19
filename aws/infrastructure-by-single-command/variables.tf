variable "aws_region" {
  description = "AWS Region."
  default     = "us-east-1"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags for AWS that will be attached to each resource."
  default = {
    "TerminationDate" = "Permanent",
    "Environment"     = "Development",
    "Team"            = "DevOps",
    "DeployedBy"      = "Terraform",
    "OwnerEmail"      = "devops@example.com"
  }
}

variable "deployment_prefix" {
  description = "Prefix of the deployment."
  type        = string
  default     = "demo"
}

variable "hosted_zone" {
  description = "hosted zone name"
  type        = string
  default     = "liubenok.pp.ua"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "demo-eks-cluster"
}

variable "cluster_users" {
  description = "EKS users"
  type        = list(any)
  default = [
    "arn:aws:iam::975050034278:user/tech_user",
    "arn:aws:iam::975050034278:user/test_user_2"
  ]
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "The OAuth2 to GitHub"
}
