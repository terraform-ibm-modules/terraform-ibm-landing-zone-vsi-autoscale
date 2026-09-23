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

output "lb_mtls_supported" {
  description = "Map of load balancer name to whether mTLS is supported, as reported by the IBM Cloud API"
  value       = { for k, lb in ibm_is_lb.lb : k => lb.mtls_supported }
}

output "security_groups" {
  description = "Security group information"
  value       = module.security_groups
}
