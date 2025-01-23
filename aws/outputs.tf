output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_al2.cluster_name
}