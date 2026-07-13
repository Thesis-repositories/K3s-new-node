variable "proxmox_api_url" {
  description = "URL API Proxmox"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token Proxmox"
  type        = string
  sensitive   = true
}

variable "vm_mac_address" {
  description = "The mac address of the new vm"
  type        = string
}

variable "ssh_public_key" {
  description = "The public ssh key"
  type        = string
}

variable "vm_hostname" {
  description = "The hostname of the new vm"
  type        = string
}

variable "target_node" {
  description = "The cluster node on which to create the new VM"
  type        = string
}

variable "template_node" {
  description = "The cluster node where the VM template is located"
  type        = string
}

variable "template_id" {
  description = "The vm id of the template"
  type = number
}

variable "vm_cpu_cores" {
  type    = number
  default = 2
}

variable "vm_memory" {
  type    = number
  default = 2048
}
