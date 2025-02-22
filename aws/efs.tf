

################################################################################
# File System
################################################################################

resource "aws_efs_file_system" "this" {

  #availability_zone_name          = var.azs
  creation_token = var.creation_token
  #performance_mode                = var.performance_mode
  encrypted  = var.encrypted
  # kms_key_id = var.kms_key_arn
  #provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  #throughput_mode                 = var.throughput_mode

  dynamic "lifecycle_policy" {
    for_each = [for k, v in var.lifecycle_policy : { (k) = v }]

    content {
      transition_to_ia                    = try(lifecycle_policy.value.transition_to_ia, null)
      transition_to_primary_storage_class = try(lifecycle_policy.value.transition_to_primary_storage_class, null)
    }
  }

  tags = merge(
    var.tags,
    { Name = var.name },
  )
}



################################################################################
# Mount Target(s)
################################################################################

resource "aws_efs_mount_target" "this" {
  for_each = { for k, v in var.mount_targets : k => v }

  file_system_id  = aws_efs_file_system.this.id
  # ip_address      = try(each.value.ip_address, null)
  security_groups = [module.eks.cluster_primary_security_group_id]
  subnet_id       = each.value
}




################################################################################
# Backup Policy
################################################################################

resource "aws_efs_backup_policy" "this" {
  count = var.create_backup_policy ? 1 : 0

  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup_policy ? "ENABLED" : "DISABLED"
  }
}

################################################################################
# Replication Configuration
################################################################################

resource "aws_efs_replication_configuration" "this" {
  count = var.create_replication_configuration ? 1 : 0

  source_file_system_id = aws_efs_file_system.this.id

  dynamic "destination" {
    for_each = [var.replication_configuration_destination]

    content {
      availability_zone_name = try(destination.value.availability_zone_name, null)
      kms_key_id             = try(destination.value.kms_key_id, null)
      region                 = try(destination.value.region, null)
    }
  }
}



