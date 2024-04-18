# Basic example

An end-to-end basic example that will provision the following:

- A new resource group if one is not passed in.
- A new public SSH key if one is not passed in.
- A new VPC with 3 subnets
- A new placement group
- A new instance template
- An instance group manager using the template with an autoscale manager with an minimum membership of 1 VSI and max membership of 4
- A policy with a CPU metric of 70
