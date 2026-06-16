# Manual Scaling Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vsi-autoscale-manual-scaling-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vsi-autoscale/tree/main/examples/manual-scaling">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example demonstrates manual control of `instance_count` without autoscale managers, addressing issue #233.

## Overview

This example provisions:
- A new resource group (if one is not passed in)
- A new public SSH key (if one is not passed in)
- A new VPC with 3 subnets
- A new placement group
- A new instance template
- An instance group with **manual scaling** (no autoscale manager)

## Key Configuration

```hcl
module "manual_scale" {
  source         = "../../"
  instance_count = 2
  auto_scale     = false  # Enables manual control of instance_count
  group_managers = []     # No autoscale managers
  # ... other configuration
}
```

## Manual Scaling Capabilities

With `auto_scale = false`, you can:

1. **Scale Up**: Increase `instance_count` from 2 to 5
   ```hcl
   instance_count = 5
   ```
   Run `terraform apply` to add 3 more instances.

2. **Scale Down**: Decrease `instance_count` from 5 to 3
   ```hcl
   instance_count = 3
   ```
   Run `terraform apply` to remove 2 instances.

3. **Cycle Instances**: Update template and cycle instances
   ```hcl
   # Change template (e.g., machine_type)
   machine_type = "cx2-4x8"

   # Scale to 0 to remove old instances
   instance_count = 0
   # Apply

   # Scale back up with new template
   instance_count = 2
   # Apply
   ```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Important Notes

- **No Autoscale Manager**: This example does not include autoscale managers
- **Manual Control**: You have full Terraform control over `instance_count`
- **No Drift**: Terraform will detect and apply any changes to `instance_count`
- **Use Case**: Ideal for predictable workloads where you want explicit control over scaling

## Comparison with Autoscale Example

| Feature | Manual Scaling (this example) | Autoscale (basic/complete) |
|---------|------------------------------|----------------------------|
| `auto_scale` | `false` | `true` (default) |
| `group_managers` | Empty `[]` | Configured with policies |
| `instance_count` control | Terraform | Autoscale manager |
| Drift detection | Enabled | Disabled (ignored) |
| Use case | Predictable workloads | Dynamic workloads |
