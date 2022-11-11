#!/bin/sh
echo "Updating packages ..."

sudo apt-get update
apt upgrade -y
sudo apt install curl wget zip unzip apt-transport-https ca-certificates gnupg-agent software-properties-common lsb-release gnupg -y

apt install curl -y
apt install wget -y
apt install unzip -y

echo "[$(date +%F_%T)] Installing Azure CLI"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#sudo apt install --only-upgrade -y azure-cli

echo "[$(date +%F_%T)] Installing Terraform"
sudo wget https://releases.hashicorp.com/terraform/1.0.4/terraform_1.0.4_linux_amd64.zip
sudo unzip terraform*.zip
sudo mv terraform /usr/local/bin

