resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${var.component_name}-${var.env}-nic${count.index}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.component_name}-${var.env}-nic${count.index}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vm_count
  name                            = "${var.component_name}-${var.env}-${count.index}"
  location                        = data.azurerm_resource_group.main.location
  resource_group_name             = data.azurerm_resource_group.main.name
  network_interface_ids           = [azurerm_network_interface.main[count.index].id]
  size                            = var.vm_size
  admin_password                  = data.azurerm_key_vault_secret.ssh_password.value
  admin_username                  = data.azurerm_key_vault_secret.ssh_username.value
  source_image_id                 = var.image_id
  disable_password_authentication = false
  secure_boot_enabled             = true
  vtpm_enabled                    = true

  user_data = base64encode(templatefile("${path.root}/userdata.sh", {
    component_name = var.component_name
    env            = var.env
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_dns_a_record" "main" {
  name                = "${var.component_name}-${var.env}"
  zone_name           = "rdevopsb89.online"
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 30
  records             = [azurerm_network_interface.main[0].private_ip_address]
}

