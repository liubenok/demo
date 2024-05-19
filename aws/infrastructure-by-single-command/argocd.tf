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
    github_repo_name = "liubenok/demo"
    version          = "6.9.3"
    namespace        = "argocd"
  }
}

# ED25519 key for ArgoCD
resource "tls_private_key" "ed25519_argocd" {
  algorithm = "ED25519"
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
