##############################################################################
# Complete example
##############################################################################

##############################################################################
# Locals
##############################################################################

locals {
  ssh_key_id = var.ssh_key != null ? data.ibm_is_ssh_key.existing_ssh_key[0].id : resource.ibm_is_ssh_key.ssh_key[0].id
  image      = "ibm-centos-7-9-minimal-amd64-12"
  vpc_name   = "complete-test"
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Server Certificate (from existing Secrets Manager instance)
# Used to exercise HTTPS listener TLS termination + mTLS pool auth
##############################################################################

module "server_cert" {
  count                  = var.existing_sm_instance_guid != null ? 1 : 0
  source                 = "terraform-ibm-modules/secrets-manager-private-cert/ibm"
  version                = "1.12.10"
  cert_name              = "${var.prefix}-server-cert"
  cert_description       = "Server certificate for LB listener TLS and pool client auth"
  cert_common_name       = "${var.prefix}-server.example.com"
  cert_template          = var.existing_sm_cert_template
  secrets_manager_guid   = var.existing_sm_instance_guid
  secrets_manager_region = var.existing_sm_instance_region
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
  version           = "9.1.2"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  resource_tags     = var.resource_tags
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
  create_security_group         = true
  ignore_instance_count_changes = true # Set to false for manual scaling control
  security_group = {
    name : "vsi-sg",
    rules : [
      {
        direction : "inbound",
        name : "allow-vpc-inbound",
        source : "10.0.0.0/8"
      },
      {
        direction = "outbound",
        name      = "allow-vpc-outbound",
        source    = "10.0.0.0/8"
      }
    ]
  }
  tags                          = var.resource_tags
  access_tags                   = var.access_tags
  subnets                       = module.slz_vpc.subnet_zone_list
  vpc_id                        = module.slz_vpc.vpc_id
  prefix                        = var.prefix
  placement_group_id            = ibm_is_placement_group.placement_group.id
  machine_type                  = "cx2-2x4"
  user_data                     = null
  skip_iam_authorization_policy = false
  existing_kms_instance_guid    = null
  kms_encryption_enabled        = false
  boot_volume_encryption_key    = null
  ssh_key_ids                   = [local.ssh_key_id]
  block_storage_volumes         = []
  instance_count                = 2
  load_balancers = [{
    name              = "srv-lb",
    type              = "public",
    listener_port     = var.existing_sm_instance_guid != null ? 443 : 80,
    listener_protocol = var.existing_sm_instance_guid != null ? "https" : "http",
    # TLS termination certificate — required when listener_protocol is "https"
    certificate_instance = var.existing_sm_instance_guid != null ? module.server_cert[0].secret_crn : null,
    connection_limit     = 10,
    protocol             = var.existing_sm_instance_guid != null ? "https" : "http",
    pool_member_port     = var.existing_sm_instance_guid != null ? 443 : 80,
    algorithm            = "round_robin",
    health_delay         = 60,
    health_retries       = 5,
    health_timeout       = 30,
    health_type          = var.existing_sm_instance_guid != null ? "https" : "tcp",
    # mTLS: forward connection metadata (including TLS info) to backends
    proxy_protocol = var.existing_sm_instance_guid != null ? "v2" : null,
    # mTLS: pool client presents this certificate when connecting to backends
    pool_client_authentication = var.existing_sm_instance_guid != null ? {
      certificate_instance = module.server_cert[0].secret_crn
    } : null,
    security_group = {
      name                         = "lb-sg",
      add_ibm_cloud_internal_rules = false,
      rules = [
        {
          direction = "inbound",
          name      = "allow-vpc-inbound",
          source    = "10.0.0.0/8"
        },
        {
          direction = "outbound",
          name      = "allow-vpc-outbound",
          source    = "10.0.0.0/8"
        }
      ]
    }
  }]
  application_port = 80
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
        name         = "policy1"
        metric_type  = "cpu"
        metric_value = 70
        policy_type  = "target"
      }]
    },
    {
      name           = "scheduled-mgr"
      manager_type   = "scheduled"
      enable_manager = true
      actions = [{
        name             = "scale-up-morning"
        cron_spec        = "0 8 * * 1-5"
        membership_count = 3
      }]
    }
  ]
}
