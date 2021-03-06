#cloud-config
package_upgrade: true
packages:
  - curl
  - wget
  - unzip
  - apt-transport-https 
  - ca-certificates 
  - gnupg-agent 
  - software-properties-common

runcmd:
 #
 # Create Folder under Home/User directory
 #
 - mkdir azagent; cd azagent
 - echo "[$(date +%F_%T)] $(pwd)" # >> ./ado_cloud_init.log
 - echo "[$(date +%F_%T)] Starting cloud_init script" # >> ./ado_cloud_init.log
 - apt install curl -y
 - apt install wget -y
 - apt install unzip -y
 #
 # Install Docker
 #
 - echo "[$(date +%F_%T)] Installing Docker"
 - apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
 - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
 - apt-key fingerprint 0EBFCD88
 - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs)  stable"
 - apt install docker.io -y
 - usermod -aG docker ${vm_admin}
 - systemctl enable docker
 - systemctl start docker
 #
 # Install Azure CLI Deb
 #
 - echo "[$(date +%F_%T)] Installing Azure CLI"
 - curl -sL https://aka.ms/InstallAzureCLIDeb | bash

 #
 # Install Docker Compose
 #
 - echo "[$(date +%F_%T)] Installing Docker Compose"
 - curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
 - chmod +x /usr/local/bin/docker-compose

 #
 # Install Kubectl
 #
 - echo "[$(date +%F_%T)] Installing Kubectl"
 - curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
 - chmod +x ./kubectl
 - mv ./kubectl /usr/local/bin

 #
 # Install Terraform 
 #
 - echo "[$(date +%F_%T)] Installing Terraform"
 - wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
 - unzip terraform*.zip
 - mv terraform /usr/local/bin

 # 
 # Install Packer
 #
 - wget "https://releases.hashicorp.com/packer/1.6.0/packer_1.6.0_linux_amd64.zip"
 - unzip packer*.zip
 - mv packer /usr/local/bin

 #
 # Downloding and installing VSTS agent package
 #
 - echo "[$(date +%F_%T)] Downloading Agent"
 - chmod ugo+rwx -R /azagent
 - curl -fkSL -o vsts-agent.tar.gz https://vstsagentpackage.azureedge.net/agent/2.164.8/vsts-agent-linux-x64-2.164.8.tar.gz
 - echo "[$(date +%F_%T)] Extracting Agent"
 - tar -zxvf vsts-agent.tar.gz 
 - chmod ugo+rwx -R /azagent
 - echo "[$(date +%F_%T)] Running installdependencies.sh"
 - ./bin/installdependencies.sh
 - echo "[$(date +%F_%T)] Running config.sh"
 - if [ "${proxy_url}" == "" ]; then echo "[$(date +%F_%T)] -- No proxy specified."; else echo "[$(date +%F_%T)] -- Proxy specified."; fi
 - if [ "${proxy_url}" == "" ]; then sudo -u ${vm_admin} ./config.sh --unattended --url "${server_url}" --auth pat --token "${pat_token}" --pool "${pool_name}" --agent $HOSTNAME --work _work --acceptTeeEula --replace; else sudo -u ${vm_admin} ./config.sh --unattended --url "${server_url}" --auth pat --token "${pat_token}" --pool "${pool_name}" --agent $HOSTNAME --work _work --acceptTeeEula --replace --proxyurl "${proxy_url}" --proxyusername "${proxy_username}" --proxypassword "${proxy_password}"; fi
 - echo "[$(date +%F_%T)] Running scv.sh"
 - ./svc.sh install
 - ./svc.sh start
 - STR='${proxy_bypass}'; echo "$STR" > /azagent/.proxybypass
 
power_state:
 delay: "+1"
 mode: reboot
 message: Rebooting after ADO configuration
 timeout: 30
 condition: True