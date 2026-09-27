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

output "lb_mtls_supported" {
  description = "Map of load balancer name to whether mTLS is supported, as reported by the IBM Cloud API"
  value       = module.auto_scale.lb_mtls_supported
}
