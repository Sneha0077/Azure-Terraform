provider "azurerm" {
 alias = "y"
  }

resource "azurerm_resource_group" "RG" {
    name     = "${var.prefix}-resources1"
    location = "${var.location}"
}

