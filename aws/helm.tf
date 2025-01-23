provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to your kubeconfig file
  # Alternatively, specify config_context if multiple contexts exist
  config_context = module.eks_al2.cluster_arn
}


provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = module.eks_al2.cluster_arn
  }
  registry {
    url      = "oci://quixcontainerregistry.azurecr.io"
    username = "tofill"
    password = "tofill"
  }
  
}


resource "helm_release" "quixmanager" {
  name       = "quixplatform-manager"
  repository = "oci://quixcontainerregistry.azurecr.io/helm"
  chart      = "quixplatform-manager"
  version    = "0.0.20250116205"  # Specify the chart version

  namespace = "quix"

  create_namespace = true

  values = [
    file("helm/values.yaml")  # Optional: Custom values
  ]
  depends_on = [ null_resource.ansible_command  ]
}