########################################################################################################################
# Outputs
########################################################################################################################

#output "myoutput" {
#  description = "Description of my output"
#  value       = "value"
#}

output "intstance_template" {
  description = "Instance template information"
  value       = ibm_is_instance_template.instance_template
}

output "ibm_is_instance_group" {
  description = "Instance group information"
  value       = ibm_is_instance_group.instance_group
}

output "lbs" {
  description = "Load balancer information"
  value       = ibm_is_lb.lb
}

output "security_groups" {
  description = "Security group information"
  value       = ibm_is_security_group.security_group
}
