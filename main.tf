# Configuration details for Terraform
terraform {
  required_providers {
    azurerm = {                     # What we need is a Azure Resource manager
      source  = "hashicorp/azurerm" # Where will this be found -- Name of the provider
      version = "~>4.42.0"          # ~ is a 'Pessimistic Constraing operator'. Don't go beyond major version 4, but use atleast minor version 42 
    }
  }
}

# Configuration details for Azure Terraform
provider "azurerm" {
  features {} # Feature flags. Must be present even if nothing is present.
  subscription_id = "1038ec51-e78c-4660-ae64-2a85587c76bf"
}

# Create a Resource group to contain all the required resources
resource "azurerm_resource_group" "my_rg0" { # azurerm_resource_group => Type of resource; rg => Contextual reference
  name     = "my_resource_group0"
  location = "South India"
  tags = {
    environment = "dev"
    source      = "Terraform"
    purpose     = "Upskill myself"
  }
}

# Create An Azure Virtual Network.
resource "azurerm_virtual_network" "my_vnet0" {
  name                = "my_virtual_network0"
  resource_group_name = azurerm_resource_group.my_rg0.name
  location            = azurerm_resource_group.my_rg0.location
  address_space       = ["10.0.0.0/16"] # Private IPs to work with within the VM. Gives us 65536 IPs to work with.  
}

# Create a Subnet
resource "azurerm_subnet" "my_subnet0" {
  name                 = "my_subnet0"
  resource_group_name  = azurerm_resource_group.my_rg0.name
  virtual_network_name = azurerm_virtual_network.my_vnet0.name
  address_prefixes     = ["10.0.1.0/24"] # Should be a subset of above IPs. Gives us 256 IPs to work with within the subnet of the VM. 
}

# Create a Network interface
resource "azurerm_network_interface" "my_nic0" {
  name                = "my_nic0"
  location            = azurerm_resource_group.my_rg0.location
  resource_group_name = azurerm_resource_group.my_rg0.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet0.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Now, Create a Public IP to connect to my network
resource "azurerm_public_ip" "my_public_ip0" {
  name                    = "my_public_ip0"
  resource_group_name     = azurerm_resource_group.my_rg0.name
  location                = azurerm_resource_group.my_rg0.location
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "dev"
  }
}

# Display the Public IP address - Instead of searching in the Azure portal.
output "public_ip_address" {
  value = azurerm_public_ip.my_public_ip0.ip_address
}

# Create a Network Security Group to wrap the [subnet], [Network Interface] and [In/Out bound IPs]
resource "azurerm_network_security_group" "my_nsg0" {
  name                = "my_nsg0"
  resource_group_name = azurerm_resource_group.my_rg0.name
  location            = azurerm_resource_group.my_rg0.location
}

# Create Network Security rule for SSH
resource "azurerm_network_security_rule" "my_ns_rule_ssh" {
  name                        = "my_ns_rule_ssh"
  priority                    = 100       # Should be unique for each rule. Lesser = More priority
  direction                   = "Inbound" # Requests are coming in, Hence Inbound
  access                      = "Allow"
  protocol                    = "Tcp" # Can be Tcp, Udp, Icmp, Esp, Ah or * (which matches all)
  source_port_range           = "*"   # Port from which client is accessing 
  destination_port_range      = "22"  # Port on the server. Requests to be accepted only on Port 22
  source_address_prefix       = "*"   # We want to accept requests from everywhere.
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.my_rg0.name
  network_security_group_name = azurerm_network_security_group.my_nsg0.name
}

# Create Network Security rule for FastAPI
resource "azurerm_network_security_rule" "my_ns_rule_fastapi" {
  name                        = "my_ns_rule_fastapi"
  priority                    = 101       # Should be unique for each rule. Lesser = More priority
  direction                   = "Inbound" # The user's browser is making a request to our VM, so the traffic is inbound.
  access                      = "Allow"
  protocol                    = "Tcp"  # Can be Tcp, Udp, Icmp, Esp, Ah or * (which matches all)
  source_port_range           = "*"    # Port from which client is accessing 
  destination_port_range      = "8000" # Port on the server. Requests to be accepted only on Port 8000
  source_address_prefix       = "*"    # We want to accept requests from everywhere.
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.my_rg0.name
  network_security_group_name = azurerm_network_security_group.my_nsg0.name
}

# Create Network Security rule for Streamlit
resource "azurerm_network_security_rule" "my_ns_rule_streamlit" {
  name                        = "my_ns_rule_streamlit"
  priority                    = 102       # Should be unique for each rule. Lesser = More priority
  direction                   = "Inbound" # The user's browser is making a request to our VM, so the traffic is inbound.
  access                      = "Allow"
  protocol                    = "Tcp"  # Can be Tcp, Udp, Icmp, Esp, Ah or * (which matches all)
  source_port_range           = "*"    # Port from which client is accessing 
  destination_port_range      = "8501" # Port on the server. Requests to be accepted only on Port 8501
  source_address_prefix       = "*"    # We want to accept requests from everywhere.
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.my_rg0.name
  network_security_group_name = azurerm_network_security_group.my_nsg0.name
}

# Connect the Network Security Group to the Subnet
resource "azurerm_subnet_network_security_group_association" "my_nsg_association" {
  subnet_id                 = azurerm_subnet.my_subnet0.id # Ids are auto-generated for every resource. 
  network_security_group_id = azurerm_network_security_group.my_nsg0.id
}

# Connect the Network Interface and a Network Security Group
resource "azurerm_network_interface_security_group_association" "my_nic_nsg_assoc0" {
  network_interface_id      = azurerm_network_interface.my_nic0.id
  network_security_group_id = azurerm_network_security_group.my_nsg0.id
}

# Create a Linux Virtual machine
resource "azurerm_linux_virtual_machine" "myvm0" {
  name                = "myvm0"
  resource_group_name = azurerm_resource_group.my_rg0.name
  location            = azurerm_resource_group.my_rg0.location
  size                = "Standard_B1s" # 1 core, 1GB RAM, 4GB temporary storage
  admin_username      = "saibharadwaj"
  network_interface_ids = [
    azurerm_network_interface.my_nic0.id
  ]

  # Create a SSH key to securely access the VM.
  admin_ssh_key {
    username   = "saibharadwaj"
    public_key = file("/home/saibharadwaja92/CreditCardFraud/ssh_keys.pub") # Don't expose it here. Keep it in a secrets type of file
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

