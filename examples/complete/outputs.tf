##############################################################################
# Outputs
##############################################################################

output "region" {
  description = "The region all resources were provisioned in"
  value       = var.region
}

output "prefix" {
  description = "The prefix used to name all provisioned resources"
  value       = var.prefix
}

output "resource_group_name" {
  description = "The name of the resource group used"
  value       = var.resource_group
}

output "resource_tags" {
  description = "List of resource tags"
  value       = var.resource_tags
}

output "intstance_template" {
  description = "Instance template information"
  value       = module.auto_scale.intstance_template
}

output "ibm_is_instance_group" {
  description = "Instance group information"
  value       = module.auto_scale.ibm_is_instance_group
}

output "lbs_list" {
  description = "Load balancer information"
  value       = module.auto_scale.lbs_list
}

output "security_groups" {
  description = "Security group information"
  value       = module.auto_scale.security_groups
}

output "instance_group_managers" {
  description = "Map of instance group manager IDs keyed by manager name."
  value       = module.auto_scale.instance_group_managers
}

output "instance_group_manager_policies" {
  description = "Map of instance group manager policy IDs keyed by policy name."
  value       = module.auto_scale.instance_group_manager_policies
}

output "instance_group_manager_actions" {
  description = "Map of instance group manager action IDs keyed by action name."
  value       = module.auto_scale.instance_group_manager_actions
}
