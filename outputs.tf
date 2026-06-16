########################################################################################################################
# Outputs
########################################################################################################################

output "intstance_template" {
  description = "Instance template information"
  value       = ibm_is_instance_template.instance_template
}

output "ibm_is_instance_group" {
  description = "Instance group information"
  value       = var.auto_scale ? ibm_is_instance_group.autoscale[0] : ibm_is_instance_group.static[0]
}

output "lbs_list" {
  description = "Load balancer information"
  value       = values(ibm_is_lb.lb)
}

output "security_groups" {
  description = "Security group information"
  value       = module.security_groups
}
