variable "vnet_name" {
  type = string
}
variable "subnet_name" {
  type = string
}
variable "lb_name" {
  type = string
}
variable "sku_type" {
  type = string
}
variable "lb_backend_pool_name" {
  type = string
}

variable "vms" {
  type = map(object({
    name = string
    size = string
  }))
}

variable "admin_username" {
  type = string
  default = "azureuser"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "load_balancer_type" {
  type = string
}

