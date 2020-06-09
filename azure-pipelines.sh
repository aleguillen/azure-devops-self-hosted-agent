#!/bin/bash

# Sign in to the Azure CLI and Set Subscription
az login
az account set --subscription <your-subscription-id-or-name>

# Adding Azure DevOps Extension
az extension add --name azure-devops

#################################################
################# Variables #####################
#################################################

ORG_NAME=<your-organization-name>
PROJECT_NAME='ado-self-hosted-agent'

ORG_URL="https://dev.azure.com/$ORG_NAME"

# Environment Name: Most common examples: DEV, ACC, PRD, QA (Abbreviate if possible)
environment='dev'

# Azure region / location. Modify as needed.
location='eastus2' 

# Prefix for all your resources. Use alphanumeric characters only. Avoid special characters. Ex. ado001
# Ex. For resource group: <prefix>-<environment>-rg
prefix='ado001'

# Azure Common tags. These tags will be apply to all created resources.
# You can add/remove tags as needed. Example: 
common_tags='{
    org_name    = "<replace-me>",
    cost_center = "<replace-me>",
    project     = "<replace-me>",
    project_id  = "<replace-me>",
    created_by  = "<replace-me>"
}'

# Virtual Machine Credentials
vm_username='adoadmin' 
vm_password='<replace-me>'

# If TRUE - Create VM Scale Set instead of Single VM.
ado_vmss_enabled=true
ado_vmss_instances='1'

# Set VM Size
ado_vm_size='Standard_DS1_v2'

# Set Image ID location
# Retrieve it from CLI or specify it as string
#vm_image_id=$(az sig image-version show --gallery-image-definition <image-def> --gallery-image-version <image-version> --gallery-name <gallery-name> --resource-group <resource-group> --query id -o tsv)
vm_image_id=""

# If no image id is set. Set image reference.
vm_image_ref='{
    publisher = "Canonical",
    offer     = "UbuntuServer",
    sku       = "18.04-LTS",
    version   = "latest"
}'

# List of Subscription Ids for Agent Pool Role Assigment Access
ado_subscription_ids_access='["<replace-me>"]'

# Azure DevOps PAT token to configure Self-Hosted Agent
ado_pat_token='<replace-me>'

# Agent Pool Nanme
ado_pool_name='Default'

# Agent Pool Proxy settings - modify if applicable
ado_proxy_url=""

ado_proxy_username=""

ado_proxy_password=""

ado_proxy_bypass_list='[]'

# ADO variable group name - if you change this name you will need to change azure-pipelines.yml file.
ado_var_group_name='ado_dev_vars'

# ADO Pipeline Name
ado_pipeline_name='ADO.Infra.CI.CD'

# Pipeline Yaml file path location
ado_pipeline_yml_path='/azure-pipelines.yml'

# Azure Repo name for pipeline.
ado_repo=$PROJECT_NAME
ado_repo_branch='master'

#################################################
################### Setup #######################
#################################################

# Set Azure DevOps defaults - organization name
az devops configure --defaults organization=$ORG_URL

# Create Project
az devops project create --name $PROJECT_NAME

# Set Azure DevOps defaults - organization name and project name
az devops configure --defaults organization=$ORG_URL project=$PROJECT_NAME

# Create Azure RM Service Connection
# Retrieve Account and Subscription details
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
APP_NAME="sp-ado-${PROJECT_NAME}-${SUBSCRIPTION_ID}"
SERVICE_CONNECTION_NAME="sc-${PROJECT_NAME}-azure-subscription"

# Create Service Principal and get Password created. Set value to environment variable.
APP_PWD=$(az ad sp create-for-rbac --name $APP_NAME --role Owner --scopes "/subscriptions/${SUBSCRIPTION_ID}" --query "password" -o tsv)
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="${APP_PWD}"

# Get other Service Principal details
APP_ID=$(az ad app list --display-name $APP_NAME --query [].appId -o tsv)

# Create Service Connection in Azure DevOps to Azure RM.
az devops service-endpoint azurerm create --azure-rm-service-principal-id $APP_ID --azure-rm-subscription-id $SUBSCRIPTION_ID --azure-rm-subscription-name "${SUBSCRIPTION_NAME}" --azure-rm-tenant-id $TENANT_ID --name $SERVICE_CONNECTION_NAME

# Grant permission access to all Pipelines 
serv_end_id=$(az devops service-endpoint list --query "[?name == '${SERVICE_CONNECTION_NAME}'].id" -o tsv)
az devops service-endpoint update --id $serv_end_id --enable-for-all true

# Import Git Repository to Azure Repos
az repos import create --git-source-url https://github.com/aleguillen/azure-devops-self-hosted-agent.git --repository $ado_repo

# Create ADO Variable group with non-secret variables
az pipelines variable-group create \
--name $ado_var_group_name \
--authorize true \
--variables \
environment=$environment \
location=$location \
prefix=$prefix \
common_tags="$common_tags" \
vm_username=$vm_username \
vm_image_id=$vm_image_id \
vm_image_ref="$vm_image_ref" \
ado_vmss_enabled=$ado_vmss_enabled \
ado_vmss_instances=$ado_vmss_instances \
ado_vm_size=$ado_vm_size \
ado_subscription_ids=$ado_subscription_ids_access \
ado_proxy_url=$ado_proxy_url \
ado_proxy_username=$ado_proxy_username \
ado_proxy_password=$ado_proxy_password \
ado_proxy_bypass_list=$ado_proxy_bypass_list \
ado_pool_name=$ado_pool_name \
resource_group='$(prefix)-$(environment)-rg' \
storagekey='PipelineWillGetThisValueRuntime' \
terraformstorageaccount='tf$(prefix)$(environment)sa' \
terraformstoragerg='tf-$(prefix)-$(environment)-rg' \
ado_server_url='$(System.TeamFoundationCollectionUri)' 

# Create Variable Secrets
VAR_GROUP_ID=$(az pipelines variable-group list --group-name $ado_var_group_name --top 1 --query "[0].id" -o tsv)
az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'vm_password' \
--value $vm_password

az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'ado_pat_token' \
--value $ado_pat_token

# Create Pipeline
az pipelines create --name $ado_pipeline_name --yaml-path $ado_pipeline_yml_path --repository $ado_repo --repository-type tfsgit --branch $ado_repo_branch
