
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

################################################################################
# EKS Module
################################################################################

data "aws_eks_cluster" "this" {

  name       = module.eks.cluster_name
  depends_on = [module.eks]

}



data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  eks_endpoint_without_http  = replace(data.aws_eks_cluster.this.endpoint, "http://", "")
  eks_endpoint_without_https = replace(local.eks_endpoint_without_http, "https://", "")
}
module "eks" {

  source = "terraform-aws-modules/eks/aws"
  #configuration
  cluster_name                         = substr(var.cluster_name, 0, 28)
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  manage_aws_auth_configmap            = var.manage_aws_auth_configmap
  create_aws_auth_configmap            = var.create_aws_auth_configmap

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # cluster_security_group_additional_rules = {
  #   access_fromothervpc = {
  #     source_security_group_id = var.ags_securitygroup_id
  #     description              = "To access from bastion to the Kubernetes API"
  #     protocol                 = "tcp"
  #     from_port                = 443
  #     to_port                  = 443
  #     type                     = "ingress"
  #   }

  # }

    node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }


  #addons
  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
      before_compute    = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  #Network
  vpc_id                   = var.vpc_id
  subnet_ids               = var.dataplane_subnet_ids
  control_plane_subnet_ids = var.controlplane_subnet_ids
  cluster_ip_family        = "ipv4"


  #nodes
  eks_managed_node_groups = {
    containerd = {
      use_custom_launch_template = false
      name                       = "quix-containerd"
      instance_types             = ["m6i.xlarge"]
      launch_template_name       = ""
      create_iam_role            = true
      iam_role_name              = "eks-quix-cluster"
      iam_role_use_name_prefix   = false
      iam_role_description       = "EKS managed node group completefor Controller"
      enable_bootstrap_user_data = true
      pre_bootstrap_user_data    = <<-EOT
      #!/bin/bash
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      export KUBELET_EXTRA_ARGS="--max-pods=110"
      export CNI_PREFIX_DELEGATION_ENABLED=true
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT
      bootstrap_extra_args       = "--container-runtime containerd --kubelet-extra-args '--max-pods=110'"
      max_size                   = 5
      desired_size               = 5
      disk_size                  = 50
    }
  }

  tags = var.tags
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}
