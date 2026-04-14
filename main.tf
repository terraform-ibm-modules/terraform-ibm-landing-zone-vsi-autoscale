locals {
  # Determine what KMS service is being used for database encryption
  kms_service = var.boot_volume_encryption_key != null ? (
    can(regex(".*kms.*", var.boot_volume_encryption_key)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.boot_volume_encryption_key)) ? "hs-crypto" : null
    )
  ) : null
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.block_storage_policy]

  create_duration = "30s"
}

##############################################################################
# Lookup default security group id in the vpc
##############################################################################

data "ibm_is_vpc" "vpc" {
  identifier = var.vpc_id
}

locals {
  default_security_group_id = data.ibm_is_vpc.vpc.default_security_group
}

##############################################################################
# Create Instance template
##############################################################################

# NOTE: The below auth policy cannot be scoped to a source resource group due to
# the fact that the Block storage volume does not yet exist in the resource group.

resource "ibm_iam_authorization_policy" "block_storage_policy" {
  count                       = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? 0 : 1
  source_service_name         = "server-protect"
  target_service_name         = local.kms_service
  target_resource_instance_id = var.existing_kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow block storage volumes to be encrypted by Key Management instance."
}

resource "ibm_is_instance_template" "instance_template" {
  name                             = var.instance_tmplt_name != null ? var.instance_tmplt_name : (var.prefix != null ? "${var.prefix}-ins-tmplt" : "ins-tmplt")
  image                            = var.image_id
  profile                          = var.machine_type
  resource_group                   = var.resource_group_id
  vpc                              = var.vpc_id
  zone                             = var.zone
  user_data                        = var.user_data
  keys                             = var.ssh_key_ids
  availability_policy_host_failure = var.availability_policy_host_failure
  placement_group                  = var.placement_group_id
  dedicated_host                   = var.dedicated_host
  dedicated_host_group             = var.dedicated_host_group

  primary_network_interface {
    subnet = var.subnets[0].id
    security_groups = flatten([
      ((var.create_security_group && var.security_group != null) ? [module.security_groups[var.security_group.name].security_group_id] : [local.default_security_group_id]),
      var.security_group_ids
    ])
    allow_ip_spoofing = var.allow_ip_spoofing
  }

  boot_volume {
    name                             = var.instance_tmplt_name != null ? var.instance_tmplt_name : (var.prefix != null ? "${var.prefix}-ins-tmplt-boot-vol" : "ins-tmplt-boot-vol")
    encryption                       = var.kms_encryption_enabled ? var.boot_volume_encryption_key : null
    delete_volume_on_instance_delete = var.auto_delete_volumes
    tags                             = var.tags
  }

  dynamic "volume_attachments" {
    for_each = var.block_storage_volumes

    content {
      name                             = var.instance_tmplt_name != null ? var.instance_tmplt_name : (var.prefix != null ? "${var.prefix}-vol" : "vol")
      delete_volume_on_instance_delete = var.auto_delete_volumes

      volume_prototype {
        capacity       = volume_attachments.value.capacity
        profile        = volume_attachments.value.profile
        encryption_key = var.kms_encryption_enabled ? var.boot_volume_encryption_key : volume_attachments.value.encryption_key
        iops           = volume_attachments.value.iops
        tags           = var.tags
      }
    }
  }
}

##############################################################################
