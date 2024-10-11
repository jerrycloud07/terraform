# Module Inputs
variable "tf_resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "tf-resource-group"
}

variable "tf_location" {
  description = "Azure region"
  type        = string
  default     = "North Europe"
}

variable "tf_names" {
  description = "Names to be applied to resources"
  type        = map(string)
  default     = {
    vm_name      = "tf-vm"
    disk_name    = "tf-os-disk"
    network_name = "tf-vnet"
  }
}

variable "tf_tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {
    environment = "production"
    project     = "terraform-azure"
  }
}

# Windows
variable "tf_windows_machine_name" {
  description = "Windows Virtual Machine Name - Max 15 characters. If left blank, randomly assigned"
  type        = string
  default     = "tf-win-vm"
}

# Linux
variable "tf_linux_machine_name" {
  description = "Linux Virtual Machine Name - If left blank, generated from metadata module"
  type        = string
  default     = "tf-linux-vm"
}

# VM Size
variable "tf_virtual_machine_size" {
  description = "Instance size to be provisioned"
  type        = string
  default     = "Standard_DS2_v2"
}

# VM Type
variable "tf_kernel_type" {
  description = "Virtual machine kernel - windows or linux"
  default     = "linux"
  type        = string
}

# Custom Machine Image
variable "tf_custom_image_id" {
  description = "Custom machine image ID"
  type        = string
  default     = null
}

# Custom User Data
variable "tf_custom_data" {
  description = "The Base64-Encoded Custom Data which should be used for this Virtual Machine"
  type        = string
  default     = null
}

# Operating System
variable "tf_source_image_publisher" {
  description = "Operating System Publisher"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "tf_source_image_offer" {
  description = "Operating System Name"
  type        = string
  default     = "WindowsServer"
}

variable "tf_source_image_sku" {
  description = "Operating System SKU"
  type        = string
  default     = "2019-Datacenter"
}

variable "tf_source_image_version" {
  description = "Operating System Version"
  type        = string
  default     = "latest"
}

# Operating System Disk
variable "tf_operating_system_disk_cache" {
  description = "Type of caching to use on the OS disk - Options: None, ReadOnly or ReadWrite"
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["none", "readonly", "readwrite"], lower(var.tf_operating_system_disk_cache))
    error_message = "OS Disk cache can only be \"None\", \"ReadOnly\" or \"ReadWrite\"."
  }
}

variable "tf_operating_system_disk_type" {
  description = "Type of storage account to use with the OS disk - Options: Standard_LRS, StandardSSD_LRS or Premium_LRS"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["standard_lrs", "standardssd_lrs", "premium_lrs", "ultrassd_lrs"], lower(var.tf_operating_system_disk_type))
    error_message = "OS Disk type can only be \"Standard_LRS\", \"StandardSSD_LRS\", \"Premium_LRS\" or \"UltraSSD_LRS\"."
  }
}

variable "tf_operating_system_disk_write_accelerator" {
  description = "Should Write Accelerator be Enabled for this OS Disk?"
  type        = bool
  default     = false
}

# Credentials
variable "tf_admin_username" {
  description = "Default Username - Random if left blank"
  type        = string
  default     = "adminuser"
}

variable "tf_admin_password" {
  description = "(Windows) Default Password - Random if left blank"
  type        = string
  default     = "P@ssw0rd1234!"
  sensitive   = true
}

variable "tf_admin_ssh_public_key" {
  description = "(Linux) Public SSH Key - Generated if left blank"
  type        = string
  default     = ""
  sensitive   = true
}

# Index
variable "tf_machine_count" {
  description = "Unique Identifier/Count - Random if left at 0"
  type        = number
  default     = 1
}

# Networking
variable "tf_public_ip_enabled" {
  description = "Create and attach a public interface?"
  type        = bool
  default     = true
}

variable "tf_public_ip_sku" {
  description = "SKU to be used with this public IP - Basic or Standard"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["basic", "standard"], lower(var.tf_public_ip_sku))
    error_message = "Public IP SKU can only be \"Basic\" or \"Standard\"."
  }
}

variable "tf_accelerated_networking" {
  description = "Enable accelerated networking?"
  type        = bool
  default     = true
}

variable "tf_proximity_placement_group" {
  description = "ID of the proximity_placement_group you want the VM to be a member of"
  type        = string
  default     = null
}

variable "tf_ultra_ssd_enabled" {
  description = "Should the capacity to enable Data Disks of the UltraSSD_LRS storage account type be supported on this Virtual Machine."
  type        = bool
  default     = false
}

variable "tf_availability_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created."
  type        = number
  default     = 1
}

# VM Identity
variable "tf_identity_type" {
  description = "The Managed Service Identity Type of this Virtual Machine. Possible values are SystemAssigned (where Azure will generate a Managed Identity for you), UserAssigned (where you can specify the Managed Identities ID)."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["systemassigned", "userassigned"], lower(var.tf_identity_type))
    error_message = "The identity type can only be \"UserAssigned\" or \"SystemAssigned\"."
  }
}

variable "tf_identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned to the VM"
  type        = list(string)
  default     = []
}

variable "tf_diagnostics_storage_account_uri" {
  description = "The Storage Account's Blob Endpoint which should hold the virtual machine's diagnostic files."
  type        = string
  default     = null
}

variable "tf_enable_boot_diagnostics" {
  description = "Whether to enable boot diagnostics on the virtual machine."
  type        = bool
  default     = true
}

# Default Subnet
resource "azurerm_virtual_network" "tf_vnet" {
  name                = var.tf_names["network_name"]
  address_space       = ["10.0.0.0/16"]
  location            = var.tf_location
  resource_group_name = var.tf_resource_group_name
  tags                = var.tf_tags
}

resource "azurerm_subnet" "tf_subnet" {
  name                 = "default-subnet"
  resource_group_name  = var.tf_resource_group_name
  virtual_network_name = azurerm_virtual_network.tf_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Use the subnet_id from the created subnet in your main configuration
output "tf_subnet_id" {
  description = "The ID of the created subnet"
  value       = azurerm_subnet.tf_subnet.id
}
