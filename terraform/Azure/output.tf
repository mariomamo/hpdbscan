output "instance_ip" {
  description = "The public ip for ssh access"
  value       = [
                  azurerm_linux_virtual_machine.hpc_machine[0].public_ip,
                  azurerm_linux_virtual_machine.hpc_machine[1].public_ip,
                  azurerm_linux_virtual_machine.hpc_machine[2].public_ip,
                  azurerm_linux_virtual_machine.hpc_machine[3].public_ip
                ]
}