# Deploy de WordPress na Azure com Terraform e Docker

## Descrição do Desafio:

Você deve criar um script Terraform que realiza o seguinte:

1. Sobe uma máquina virtual (VM) na Azure.
2. Configura a VM para instalar Docker.
3. Sobe um container com o WordPress instalado na VM.

## Passo-a-Passo

### Parte 1: Instalação e Configuração Inicial do Terraform
1.	Instalar o Terraform
Se você ainda não tem o Terraform instalado, siga estes passos para instalar:

->	No Windows:
-	Baixe o binário do Terraform no site oficial: Terraform Downloads.
-	Extraia o arquivo e adicione o caminho do executável do Terraform às variáveis de ambiente do Windows.
-	No Explorador de Arquivos, clique com o botão direito do mouse sobre Este Computador” - Configurações avançadas do sistema - Variáveis do ambiente
-	Path - Editar - Novo
 
->	No macOS:
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

->	No Linux:
```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

2.	Verifique a Instalação do Terraform
Execute o seguinte comando para verificar se o Terraform foi instalado corretamente:
```
terraform --version
```

Você deve ver a versão do Terraform como saída.

### Parte 2: Configuração das Credenciais do Azure
Para que o Terraform possa interagir com a Azure, precisamos configurar as credenciais de acesso. Vamos usar o Azure CLI para isso:

1.	Instale o Azure CLI
->	Windows: Baixe e instale o Azure CLI a partir do site oficial.

-> macOS:
```brew install azure-cli```

-> Linux:
```curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash```

2.	Faça login na Azure CLI
Execute o comando abaixo para autenticar sua conta:
```az login```
Após a autenticação, o Azure CLI abrirá uma página da web para você fazer login na sua conta Azure.

4.	Obtenha o ID da Assinatura e o ID do Tenant
Execute o comando a seguir para listar suas assinaturas e anote o subscriptionId e tenantId:
```az account list --output table```

Parte 3: Criação do Script Terraform para a Máquina Virtual
Agora que o Terraform está instalado e as credenciais configuradas, vamos criar o script Terraform.
Estrutura de Arquivos
Crie um diretório para seu projeto Terraform e crie os seguintes arquivos dentro dele:
•	main.tf: Arquivo principal do Terraform.
•	variables.tf: Definição das variáveis do Terraform.
•	outputs.tf: Saída dos valores do Terraform.

Conteúdo do main.tf
```
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ls"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "TerraformDemo"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo docker run --name wordpress -p 80:80 -d wordpress"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      private_key = file(var.ssh_private_key_path)
      host     = azurerm_public_ip.public_ip.ip_address
    }
  }
}
```
 
Conteúdo do variables.tf
```
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
```

Conteúdo do outputs.tf
```
output "public_ip" {
  description = "Endereço IP público da máquina virtual"
  value       = azurerm_public_ip.public_ip.ip_address
}
```

### Parte 4: Configuração da VM para Instalar Docker
Já incluímos no main.tf um provisioner "remote-exec" que executa comandos remotos na VM após sua criação. Isso instalará o Docker e iniciará um container WordPress automaticamente.

### Parte 5: Execução do Script Terraform
Agora que tudo está configurado, podemos executar o script Terraform.

1.	Inicialize o Terraform
Navegue até o diretório onde seus arquivos .tf estão localizados e execute:
```terraform init```
Isso inicializará o ambiente Terraform, baixando os provedores necessários.

2.	Planeje a Execução
Execute o comando a seguir para ver o que o Terraform irá criar sem executar nenhuma mudança:
```
terraform plan
```
Certifique-se de que tudo está conforme o esperado.

3.	Aplique as Configurações
Para criar a infraestrutura, execute:
```terraform apply```
O Terraform mostrará um resumo das ações que serão realizadas. Digite yes para confirmar e aplicar as mudanças.

4.	Acesse o WordPress
Após a execução bem-sucedida, você verá o endereço IP público da VM na saída. Use este IP para acessar o WordPress em um navegador.
```http://<endereço-ip-público>```
