variable "resource_group_name" {
  description = "Nome do grupo de recursos a ser criado"
  default     = "wordpress-rg"
}

variable "location" {
  description = "Localização da Azure para o grupo de recursos"
  default     = "East US"
}

variable "admin_username" {
  description = "Nome de usuário do administrador para a VM"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Caminho para a chave pública SSH"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Caminho para a chave privada SSH"
  default     = "~/.ssh/id_rsa"
}
