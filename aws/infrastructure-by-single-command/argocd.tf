provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}


locals {
  argocd = {
    github_repo_name = "demo"
    version          = "6.9.3"
    namespace        = "argocd"
  }
}

provider "github" {
  token = var.github_token # or `GITHUB_TOKEN`
}

# Generate an ssh key using provider "hashicorp/tls"
resource "tls_private_key" "ed25519_argocd" {
  algorithm = "ED25519"
}

# Add the ssh key as a deploy key
resource "github_repository_deploy_key" "k8s_repo" {
  title      = "Repository test key"
  repository = local.argocd.github_repo_name
  key        = tls_private_key.ed25519_argocd.public_key_openssh
  read_only  = true
}



resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = local.argocd.version
  namespace        = local.argocd.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/values.yaml", {
      k8s_ssh_private_key = tls_private_key.ed25519_argocd.private_key_openssh,
      k8s_repo            = local.argocd.github_repo_name,
      host                = var.hosted_zone
    })
  ]

  depends_on = [
    module.eks
  ]
}
##################### Deploy initial bootstrap ArgoCD app #####################

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}