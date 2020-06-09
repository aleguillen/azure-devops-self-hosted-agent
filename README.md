# Azure DevOps Self-Hosted Agent

## Overview 
Azure self-hosted agent pool configuration. This will create a VM or VMSS and configure to be part of the defined Agent Pool. You can execute this locally or using Azure Pipelines.

## Pre-requisites

* Azure CLI, and the Azure CLI AKS Preview extension.
    * See how to install Azure CLI [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
    ```bash
    # Confirm AZ CLI installation
    az --version

    # Install the aks-preview extension
    az extension add --name aks-preview
    
    # Update the extension to make sure you have the latest version installed
    az extension update --name aks-preview
    ```
* HashiCorp Terraform.
    * See how to install Terraform [here](https://learn.hashicorp.com/terraform/azure/install_az).
* Install Azure DevOps Extension.
    ```bash
    # Confirm AZ CLI installation
    az --version

    # Install and confirm Azure DevOps extension.
    az extension add --name azure-devops
    az extension show --name azure-devops
    ```
* Git to manage your repository locally.
    *  See how to install [here](https://git-scm.com/downloads).

### Architecture 

![](/images/Architecture.PNG)

## Azure Pipelines Setup

You can use [Azure DevOps CLI script](/azure-pipelines.sh) to configure configure it (recommended) or you can use DevOps portal and perform these steps manually:

* [Login or Sign Up](https://dev.azure.com) into your Azure DevOps Organization.
* Create a new project in Azure DevOps, for information see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project).
    * Sample name: **ado-self-hosted-agent**
* For the Agent pool, we will be using **Default** Agent Pool. 
    *Alternately you can create a new Agent Pool in your project, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues), if you do update all pipelines files **azure-pipelines.yml** file and variable group value.
        * Example Name: **MyPrivatePool**
        * Keep option **Grant access permission to all pipelines** checked.
* Create a new Azure Service Connection to your Azure Subscription, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
    * Connection type: **Azure Resource Manager**.
    * Authentication Method: **Service Principal (automatic)** - this option will automatically create the Service Principal on your behalf, if you don't have permissions to create a Service Principal please use the manual option. 
    * Scope level: Select the appropiate level, for this project I used **Subscription**.
    * Service connection name: **sc-ado-self-hosted-agent-azure-subscription**.
* Create a Personal Access Token (PAT token), we will use this token to configure the Self Hosted Agent for Azure DevOps. For more information on how to create a PAT token see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate).
* [Import Git](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository) repo into your Azure DevOps project.
    * Git source Url: https://github.com/aleguillen/azure-devops-self-hosted-agent.git
* (Optional) Clone imported repo in your local computer, for more info see [here](https://docs.microsoft.com/en-us/azure/devops/repos/git/clone).
* Create ADO Variable group **ado_dev_vars**. Replace variables with your own preferred values, also check for all **<-replace-me->** values and update them accordingly. 
    * In the left panel, click and expand **Pipelines**.
    * Under Pipelines, click **Library**.
    * Click the **+ Variable group** button.
    * Enter a name for the variable group in the Variable Group Name field.
        * Variable group name: **ado_dev_vars**
        * Description example: **ADO Development Variables**
    * Click the **+ Add** button to create a new variable for the group.
    * Fill in the variable Name and Value. Here is an example

    | Name | Example Value | Is Secret |
    | -- | -- | -- |
    | environment | dev | No |
    | location | eastus2 | No |
    | prefix | ado001 | No |
    | common_tags | { <br>org_name    = "<-replace-me->",<br>cost_center = "<-replace-me->",<br>project     = "<-replace-me->",<br>project_id  = "<-replace-me->",<br>created_by  = "<-replace-me->"<br>} | No |
    | vm_username | adoadmin | No |
    | vm_password | <-replace-me-> | Yes |
    | vm_image_id |  | No | 
    | vm_image_ref | {<br>publisher = "Canonical",<br>offer     = "UbuntuServer",<br>sku       = "18.04-LTS",<br>version   = "latest"<br>} | No |
    | ado_vmss_enabled | true | No |
    | ado_vmss_instances | 1 | No | 
    | ado_vm_size | Standard_DS1_v2 | No |
    | ado_subscription_ids | ["<-replace-me->"] | No |
    | ado_pat_token | <-replace-me-> | Yes |
    | ado_pool_name | Default | No |
    | ado_proxy_url |  | No |
    | ado_proxy_url |  | No |
    | ado_proxy_password |  | Yes |
    | ado_proxy_bypass_list |  | No |
    | resource_group | $(prefix)-$(environment)-rg | No |
    | storagekey | PipelineWillGetThisValueRuntime | No |
    | terraformstorageaccount | tf$(prefix)$(environment)sa' | No |
    | terraformstoragerg | tf-$(prefix)-$(environment)-rg | No |
    | ado_server_url | $(System.TeamFoundationCollectionUri) | No |
    | ado_service_connection_name | Azure Susbcription | No |

    
## Running with Terraform locally

* Copy and paste file **terraform.tfvars** and name the new file **terraform.auto.tfvars** use this new file to set your local variables values. Terraform will use this file instead for local executions, for more information see [here](https://www.terraform.io/docs/configuration/variables.html#variable-definition-precedence).
* Comment line 'backend "azurerm" {}' inside **terraform.tf**. You can use Azure CLI authentication locally.
* Run the following commands.

    ```bash
    # Login into Azure
    az login 

    # Run Terraform commands:
    # Initialize a Terraform working directory
    terraform init
    # Generate and show an execution plan
    terraform plan
    # Builds or changes infrastructure. Using -auto-approve will skip interactive approval of plan before applying. 
    terraform apply -auto-approve
    ```
