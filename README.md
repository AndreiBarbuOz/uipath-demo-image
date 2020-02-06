# UiPath demo image

## Purpose

Build an Image using `Packer` and `Ansible`, based on the build instructions and playbooks found in this repository.

## Architecture 

![Architecture](https://www.lucidchart.com/publicSegments/view/c810404e-7b5f-4b2e-b51b-23a832058d53/image.png)

![Variables](https://www.lucidchart.com/publicSegments/view/083100cb-44a8-4221-a59e-755ac8cb7191/image.png)

![Greater picture](https://www.lucidchart.com/publicSegments/view/8b307462-4e6c-4262-a7b0-9ac1bc862546/image.png)

## Development environment 

### Provisioning the VM for dev and test
During development and testing, a VM needs to be provisioned, using the ARM template: 

```bash
az group deployment create --resource-group <resource-group> --template-file .\azure-deploy-vm.template.json --name demoImage --parameters adminPassword=<password>
```
The output from the command contains the key `output`, which indicates the fully qualified domain name of the VM which was provisioned. This is used in the `inventory.ini` file as an input to Ansible. This can also be obtained later using: 

```
az group deployment show --name demoImage --resource-group <resource-group>
```
Use these values to update the inventory file:

```ini
[default]
100.100.100.100

[default:vars]
ansible_connection=winrm
ansible_port=5986
ansible_winrm_transport=basic
ansible_user=uipath
ansible_password=*****
ansible_winrm_message_encryption=auto
ansible_winrm_server_cert_validation=ignore
```

### Setup the VM
After the VM is provisioned, the following script to configure Ansible script needs to be run using `Run as Administrator` Powershell:

```powershell
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file
```

### Local dev machine setup

On the local dev machine, at least `Ansible` and `Packer` should be installed. This can be performed using: 

```bash
apt-get update && \
    apt-get install -y software-properties-common unzip python-pip wget sudo && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y ansible && \
    pip install -U "pywinrm>=0.3.0"

PACKER_VERSION="1.4.1"
wget https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
    mv packer /usr/local/bin    
```

### Ansible and Packer
Against the dev machine, the Ansible playbook can be run using: 

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml -vvvv
```

The Packer script can be invoked using: 
```bash
packer build -var-file=packer/parameters.json packer/packer-build.json
```

## Prerequisites

The VMs created using the image need to have access to the KeyVault containing the refresh token to authenticate to Orhcestrator. For this:

```
az identity create --name access-key-vault --resource-group presales-cloud-poc-rg
az vm identity assign --resource-group presales-cloud-poc-rg --name linux-test --identities access-key-vault
keyId=$(az keyvault show --name test-vault-presales --resource-group presales-cloud-poc-rg --output tsv --query id)
az role assignment create --role owner --assignee access-key-vault --scope $keyId
```


The list of items needed for development and deployment:
* Azure account
* Development machine with `Packer` and `Ansible` installed
* (Optional - when using an Azure Linux VM for development) Create a `system assigned identity` for the VM and assign the role of owner over the container registry:

    ```
    az vm identity assign --resource-group <resource group name> --name <linux machine> 
    spID=$(az vm show --resource-group <resource group name> --name <linux machine> --query identity.principalId --out tsv)
    resourceID=$(az acr show --resource-group <resource group name> --name <container name> --query id --output tsv)
    az role assignment create --assignee $spID --scope $resourceID --role owner
    ```
    This will allow `az acr login --identity` using the aforementioned identity
* An `Azure Pipeline` build triggered by the repository
* The `Azure Pipeline` needs to have variable group called `demo-vm-deploy` containing these values:
    - containerRegistry
    - azureSubscription
    - repositoryName
    - dockerConnection
    - packerClientId
    - resourceGroupName
    - subscriptionId

