#!/bin/sh
echo "Updating packages ..."

while sudo fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do echo 'Waiting for release of dpkg/apt locks'; sleep 15; done; sudo apt-get install -y curl wget unzip apt-transport-https ca-certificates gnupg-agent software-properties-common lsb-release gnupg;
while sudo fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do echo 'Waiting for release of dpkg/apt locks'; sleep 15; done; sudo apt-get update

echo "[$(date +%F_%T)] Installing Azure CLI"
while sudo fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do echo 'Waiting for release of dpkg/apt locks'; sleep 15; done; curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#sudo apt install --only-upgrade -y azure-cli

echo "[$(date +%F_%T)] Installing Terraform"
sudo wget https://releases.hashicorp.com/terraform/1.0.4/terraform_1.0.4_linux_amd64.zip
apt install unzip -y
sudo unzip terraform*.zip
sudo mv terraform /usr/local/bin

