locals {
  # Validation (approach based on https://github.com/hashicorp/terraform/issues/25609#issuecomment-1057614400)
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && var.boot_volume_encryption_key != null ? tobool("When passing values for var.boot_volume_encryption_key, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && var.boot_volume_encryption_key == null ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.boot_volume_encryption_key") : true
  # tflint-ignore: terraform_unused_declarations
  validate_auth_policy = var.kms_encryption_enabled && var.skip_iam_authorization_policy == false && var.existing_kms_instance_guid == null ? tobool("When var.skip_iam_authorization_policy is set to false, and var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_guid in order to create the auth policy.") : true

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
  name                             = "${var.prefix}-ins-tmplt"
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
      (var.create_security_group ? [ibm_is_security_group.security_group[var.security_group.name].id] : []),
      var.security_group_ids,
      (var.create_security_group == false && length(var.security_group_ids) == 0 ? [data.ibm_is_vpc.vpc.default_security_group] : []),
    ])
    allow_ip_spoofing = var.allow_ip_spoofing
  }

  boot_volume {
    name                             = "${var.prefix}-ins-tmplt-boot-vol"
    encryption                       = var.kms_encryption_enabled ? var.boot_volume_encryption_key : null
    delete_volume_on_instance_delete = var.auto_delete_volumes
    tags                             = var.tags
  }

  dynamic "volume_attachments" {
    for_each = var.block_storage_volumes

    content {
      name                             = "${var.prefix}-${volume_attachments.value.name}-vol"
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
