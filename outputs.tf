########################################################################################################################
# Outputs
########################################################################################################################

output "intstance_template" {
  description = "Instance template information"
  value       = ibm_is_instance_template.instance_template
}

output "ibm_is_instance_group" {
  description = "Instance group information"
  value       = var.ignore_instance_count_changes ? ibm_is_instance_group.instance_group_with_unmanaged_instance_count[0] : ibm_is_instance_group.instance_group_with_managed_instance_count[0]
}

output "lbs_list" {
  description = "Load balancer information"
  value       = values(ibm_is_lb.lb)
}

output "security_groups" {
  description = "Security group information"
  value       = module.security_groups
}
