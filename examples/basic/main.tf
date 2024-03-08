##############################################################################
# Locals
##############################################################################

locals {
  ssh_key_id = var.ssh_key != null ? data.ibm_is_ssh_key.existing_ssh_key[0].id : resource.ibm_is_ssh_key.ssh_key[0].id
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.4"
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
  version           = "7.13.2"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  name              = var.vpc_name
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
# Provision VSI
#############################################################################

module "auto_scale" {
  source                        = "../../"
  resource_group_id             = module.resource_group.resource_group_id
  zone                          = "${var.region}-1"
  image_id                      = var.image_id
  create_security_group         = var.create_security_group
  security_group                = var.security_group
  tags                          = var.resource_tags
  access_tags                   = var.access_tags
  subnets                       = module.slz_vpc.subnet_zone_list
  vpc_id                        = module.slz_vpc.vpc_id
  prefix                        = var.prefix
  placement_group_id            = ibm_is_placement_group.placement_group.id
  machine_type                  = var.machine_type
  user_data                     = var.user_data
  skip_iam_authorization_policy = var.skip_iam_authorization_policy
  existing_kms_instance_guid    = var.existing_kms_instance_guid
  kms_encryption_enabled        = var.kms_encryption_enabled
  boot_volume_encryption_key    = var.boot_volume_encryption_key
  ssh_key_ids                   = [local.ssh_key_id]
  block_storage_volumes         = var.block_storage_volumes
  instance_count                = var.instance_count
  load_balancers                = var.load_balancers
  application_port              = var.application_port
  group_managers                = var.group_managers
}
