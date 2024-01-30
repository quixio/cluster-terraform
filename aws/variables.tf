################################################################################
# Cluster config
################################################################################
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
  default     = null
}




variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "manage_aws_auth_configmap" {
  description = "Determines whether to manage the aws-auth configmap"
  type        = bool
  default     = true
}

variable "create_aws_auth_configmap" {
  description = "Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap`"
  type        = bool
  default     = false
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "ID of the VPC where the cluster security group will be provisioned"
  type        = string
  default     = null
}

variable "ags_securitygroup_id" {
  description = "ID of security of ASG to allow the access of the k8s API from bastion"
  type        = string
  default     = null
}



variable "controlplane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned."
  type        = list(string)
  default     = []
}

variable "dataplane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster data plane (ENIs) will be provisioned."
  type        = list(string)
  default     = []
}

################################################################################
# node groups
################################################################################


variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}




variable "name" {
  description = "The name of the file system"
  type        = string
  default     = ""
}


################################################################################
# File System
################################################################################


variable "creation_token" {
  description = "A unique name (a maximum of 64 characters are allowed) used as reference when creating the Elastic File System to ensure idempotent file system creation. By default generated by Terraform"
  type        = string
  default     = null
}

# variable "performance_mode" {
#   description = "The file system performance mode. Can be either `generalPurpose` or `maxIO`. Default is `generalPurpose`"
#   type        = string
#   default     = null
# }

variable "encrypted" {
  description = "If `true`, the disk will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key. When specifying `kms_key_arn`, encrypted needs to be set to `true`"
  type        = string
  default     = null
}

# variable "provisioned_throughput_in_mibps" {
#   description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with `throughput_mode` set to `provisioned`"
#   type        = number
#   default     = null
# }

# variable "throughput_mode" {
#   description = "Throughput mode for the file system. Defaults to `bursting`. Valid values: `bursting`, `provisioned`. When using `provisioned`, also set `provisioned_throughput_in_mibps`"
#   type        = string
#   default     = null
# }

variable "lifecycle_policy" {
  description = "A file system [lifecycle policy](https://docs.aws.amazon.com/efs/latest/ug/API_LifecyclePolicy.html) object"
  type        = any
  default     = {}
}
################################################################################
# Mount Target(s)
################################################################################

variable "mount_targets" {
  description = "A map of mount target definitions to create"
  type        = any
  default     = {}
}



################################################################################
# Security group
################################################################################
variable "vpc_security_group_ids" {
  type        = list(string)
  default     = [""]
  description = "Specify which Security groups will be used"
}

################################################################################
# Backup Policy
################################################################################

variable "create_backup_policy" {
  description = "Determines whether a backup policy is created"
  type        = bool
  default     = true
}

variable "enable_backup_policy" {
  description = "Determines whether a backup policy is `ENABLED` or `DISABLED`"
  type        = bool
  default     = true
}

################################################################################
# Replication Configuration
################################################################################

variable "create_replication_configuration" {
  description = "Determines whether a replication configuration is created"
  type        = bool
  default     = false
}

variable "replication_configuration_destination" {
  description = "A destination configuration block"
  type        = any
  default     = {}
}



################################################################################
# Tags
################################################################################
variable "tags" { 
default = {     
   environment  = "string"
   created-by   = "quix"
   }
type = map(string)
}
