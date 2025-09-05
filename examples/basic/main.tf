##############################################################################
# Locals
##############################################################################

locals {
  ssh_key_id = var.ssh_key != null ? data.ibm_is_ssh_key.existing_ssh_key[0].id : resource.ibm_is_ssh_key.ssh_key[0].id
  vpc_name   = "basic-test"
  image      = "ibm-centos-7-9-minimal-amd64-12"
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.3.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create new SSH key
##############################################################################

resource "tls_private_key" "tls_key" {
  count     = var.ssh_key != null ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "ssh_key" {
  count      = var.ssh_key != null ? 0 : 1
  name       = "${var.prefix}-ssh-key"
  public_key = resource.tls_private_key.tls_key[0].public_key_openssh
}

data "ibm_is_ssh_key" "existing_ssh_key" {
  count = var.ssh_key != null ? 1 : 0
  name  = var.ssh_key
}

#############################################################################
# Provision VPC
#############################################################################

module "slz_vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "8.2.1"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  name              = local.vpc_name
}

#############################################################################
# Placement group
#############################################################################

resource "ibm_is_placement_group" "placement_group" {
  name           = "${var.prefix}-host-spread"
  resource_group = module.resource_group.resource_group_id
  strategy       = "host_spread"
  tags           = var.resource_tags
}

#############################################################################
# Provision Autoscale VSI
#############################################################################
data "ibm_is_image" "image" {
  name = local.image
}

module "auto_scale" {
  source                        = "../../"
  resource_group_id             = module.resource_group.resource_group_id
  zone                          = "${var.region}-1"
  image_id                      = data.ibm_is_image.image.id
  create_security_group         = false
  security_group                = null
  tags                          = var.resource_tags
  access_tags                   = var.access_tags
  subnets                       = module.slz_vpc.subnet_zone_list
  vpc_id                        = module.slz_vpc.vpc_id
  prefix                        = var.prefix
  placement_group_id            = ibm_is_placement_group.placement_group.id
  machine_type                  = "cx2-2x4"
  user_data                     = null
  skip_iam_authorization_policy = true
  existing_kms_instance_guid    = null
  kms_encryption_enabled        = false
  boot_volume_encryption_key    = null
  ssh_key_ids                   = [local.ssh_key_id]
  block_storage_volumes         = []
  instance_count                = 1
  load_balancers                = []
  application_port              = null
  group_managers = [
    {
      name                 = "test"
      aggregation_window   = 120
      cooldown             = 300
      manager_type         = "autoscale"
      enable_manager       = true
      max_membership_count = 4
      min_membership_count = 1
      policies = [{
        name         = "policy-1"
        metric_type  = "cpu"
        metric_value = 70
        policy_type  = "target"
      }]
    }
  ]
}
