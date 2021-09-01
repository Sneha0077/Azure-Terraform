

provider "azurerm" {
  features {}
    
}

data "azurerm_subscription" "primary" {
    subscription_id = "5498d3f6-c885-4e6f-a87b-8be98c97e968"
}

resource "random_uuid" "test" {
}

module "role-assignment" {
  source  = "andrewCluey/role-assignment/azurerm"
  version = "1.0.0"
  # insert the 3 required variables here
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "${var.prefix}-resources"
    location = "${var.location}"

 

}
resource "azurerm_virtual_network" "myVnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

}

resource "azurerm_subnet" "myterraformsubnet" {

    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myVnet.name
    address_prefixes       = ["10.0.1.0/24"]
}



resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = azurerm_resource_group.myterraformgroup.location
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        
    }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"



}


data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}



resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "${var.prefix}-vm"
    location              = azurerm_resource_group.myterraformgroup.location
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    admin_password = random_password.password.result
    disable_password_authentication = false

 identity {
    type = "SystemAssigned"
  }

}
resource "azurerm_role_assignment" "example" {
  name               = "${random_uuid.test.result}-rg"
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = "${data.azurerm_subscription.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = azurerm_linux_virtual_machine.myterraformvm.identity[0].principal_id
}
