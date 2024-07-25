output "public_ip" {
  description = "Endereço IP público da máquina virtual"
  value       = azurerm_public_ip.public_ip.ip_address
}
