variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "pow-rg"
}

variable "environment" {
  description = "Deployment environment: Dev, Stage, or Prod"
  type        = string
  default     = "Dev"
  validation {
    condition     = contains(["Dev", "Stage", "Prod"], var.environment)
    error_message = "environment must be one of: Dev, Stage, Prod."
  }
}

variable "name_prefix" {
  description = "Prefix used for all resource names"
  type        = string
  default     = "tfa"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "vm_size_map" {
  description = "VM size per environment"
  type        = map(string)
  default = {
    Dev   = "Standard_B1s"
    Stage = "Standard_B2s"
    Prod  = "Standard_B2ms"
  }
}

variable "vmss_subnet_name" {
  description = "Subnet name (key from var.subnets) to place the VMSS NICs"
  type        = string
  default     = "AppSubnet"
}

variable "subnets" {
  description = "Map of subnet names to their CIDR prefixes"
  type = map(object({
    address_prefix = string
  }))
  default = {
    AppSubnet = { address_prefix = "10.0.1.0/24" }
    ManSubnet = { address_prefix = "10.0.2.0/24" }
  }
}

variable "lb_allowed_ports" {
  description = "Ports to allow from Azure Load Balancer to the VMSS/backend subnets"
  type        = list(number)
  default     = [80, 22]
}

variable "vmss_capacity" {
  description = "Autoscale capacity settings"
  type = object({
    minimum = number
    default = number
    maximum = number
  })
  default = {
    minimum = 2
    default = 2
    maximum = 5
  }
}

variable "vmss_zones" {
  description = "Optional availability zones for the VMSS; leave empty to deploy regional (no zones)"
  type        = list(string)
  default     = []
}