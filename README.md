## Scalable Web Application Infrastructure on Azure with Terraform
### 📌 Project Overview

This project provisions a scalable web application infrastructure in Azure using Terraform. The architecture includes a Virtual Machine Scale Set (VMSS) deployed behind an Azure Load Balancer, with proper networking, security, and auto-scaling configurations.

### 1. Networking

- A Virtual Network (VNet) with two subnets:
    - Application Subnet → used by the VMSS

    - Management Subnet → reserved for future use

- A Network Security Group (NSG) that:

    - Allows traffic only from the Load Balancer to the VMSS.

    - Uses dynamic blocks for rule configuration.

    - Denies all other inbound traffic by default.

### Compute

 - A VM Scale Set (VMSS) configured with:

    - Ubuntu 20.04 LTS

    - Environment-based VM sizes (via lookup() function):

        - Dev → Standard_B1s

        - Stage → Standard_B2s

        - Prod → Standard_B2ms

- Auto-scaling policies:

    - Scale in when CPU < 10%

    - Scale out when CPU > 80%

    - Minimum instances: 2

    - Maximum instances: 5


### Load Balancer

- An Azure Load Balancer configured with:

    - A Public IP

    - A Backend Pool connected to the VMSS

    - A Health Probe on port 80

    - Load balancing rules (defined using dynamic blocks)