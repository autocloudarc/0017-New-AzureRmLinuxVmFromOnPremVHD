#!/bin/bash
<<HEADER
DESCRIPTION
This Linux shell script will upload a previously prepared specilized *.vhd Virtual Machine image from an on-premisses hypervisor to Azure, then deploy an Azure Linux VM from this *.vhd using commands from the Azure CLI.
A CentOS 7 VM was used to test this script, but other Linux distros can be used as well (see REFERENCES: item 2 below).
For instructions on how to prepare a specialized Linux VM onpremises for Azure, please see REFERENCES item 2 also.

REQUIREMENTS: 
1. An Azure subscription. If you or your organization does not already have a subscription, start here: https://azure.microsoft.com/en-us/
2. An on-premises hypervisor. See REFERENCES: items for more information.

ARGUMENTS:
-s Existing subscription in which uploaded specialized VM will be provisioned.
-v Existing source path for *.vhd file that will be uploaded to Azure blob storage.
-r Existing resource group that contains all network storage and compute resources associated with this *.vhd specialized image.
-l Azure region associated with the existing resource group to which this image will be uploaded and provisioned.
-c New Azure storage account container name that will be created by this script to host the uploaded *.vhd specialized image for the Azure VM.
-m New Azure VM name that will be used when creating the new specialized VM in Azure.
-a Existing availability set into which the new Azure VM will be placed for update and failure domain fault tolerance.
-t One or more new space-separated arbitrary tags for the new Azure VM that will be deployed.
-u Existing Azure subnet into which the new Azure VM will be deployed.
-e Exisitng Azure virtual network that contains the target subnet (-u) above.
-z New disk size in GB of managed disk for new Azure VM.

EXAMPLE:
New-AzureRmLinuxVmFromOnPremVHD.sh -s 'MySubscription' \
-v '/mnt/d/vhd/MyOnPremVmImageForAzure.vhd' \
-r 'myResourceGroup' \
-l 'eastus2' \
-c 'containerforvhd' \
-m 'myVmName' \
-a 'MyAvilabilitySet' \
-t 'distro=CentOS7' \
-u 'MySubnetName' \
-e 'MyVnetName' \
-z 32

SYNTAX:      	
New-AzureRmLinuxVmFromOnPremVHD.sh -s <subscription> -v <vhdSource> -r <resourceGroup> -l <location> -c <container> -m <machineName> -a <avSet> -t <tag> -u <subnetName> -e <vNetName> -z <diskSizeGB>

KEYWORDS	: Azure, Linux, VM

LICENSE		:
MIT License

Copyright (c) 2017 Preston K. Parsard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the SoftwSare is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
S
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

LEGAL DISCLAIMER:
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.� 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.� 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys� fees, that arise or result from the use or distribution of the Sample Code.
This posting is provided "AS IS" with no warranties, and confers no rights.

REFERENCES:
1. https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-centos
2. https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-generic
3. https://docs.microsoft.com/en-us/azure/virtual-machines/linux/upload-vhd
4. https://github.com/paulomarquesc/AzureCLI2.0BashDeployment/blob/master/azuredeploy.sh
5. https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/

**FEEDBACK**
Feel free to ask questions, provide feedback, contribute, file issues, etc. so we can make this even better!
HEADER

# Evaluate the arguments provided
while getopts s:v:r:l:c:m:a:t:d:u:e:z option
do
    case "${option}"
	in
		s) sub=${OPTARG};;
        v) vhdSource=${OPTARG};;
		r) resourceGroup=${OPTARG};;
		l) location=${OPTARG};;
		c) container=${OPTARG};;
		m) machineName=${OPTARG};;
		a) avSet=${OPTARG};;
		t) tag=${OPTARG};;
		u) subnetName=${OPTARG};;
		e) vNetName=${OPTARG};;
		z) diskSizeGB=${OPTARG};;
	esac
done

### DEFAULT/DERIVED PARAMETERS
# Derive blobName from vhdSource as the filename only
blobName="$machineName.vhd"
# Derive managed disk name from machine name.
managedDiskName="$machineName-SYST"
# Use Standard_LRS sku to minimize cost
storageSku='Standard_LRS'
# Create D1v2 VM to minimize cost while allowing acceptable performance
vmSize='Standard_D1_v2'
# Use page blobs as this is required for *.vhd files.
blobType='page'
# OS Type will be linux
os='linux'
# Network interface. 
vmNic="$machineName-nic"
# Public IP configuration.
vmPip="$machineName-pip"

### INPUT PARAMETERS
echo "INPUT PARAMETERS:"
# Subscription in which uploaded specialized VM will be provisioned
echo "subscription ${sub}"
# Source path for *.vhd file that will be uploaded to Azure blob storage
echo "vhdSource ${vhdSource}"
# Resource group that contains all network, storage and compute resources associated with this *.vhd specialized image
echo "resourceGroup ${resourceGroup}" 
# Azure region
echo "location ${location}"
# Container in storage account into which *.vhd blob will be placed for specialized VM deployment
echo "container ${container}"
# Azure VM name
echo "machineName ${machineName}"
# Availability set for fault tolerance
echo "avSet=${avSet}"
# Accepts a single tag only
echo "tag=${tag}"
# Subnet where VM will be deployed in Azure.
echo "subnetName=${subnetName}"
# Virtual network where VM will be deployed in Azure.
echo "vNetName=${vNetName}"
# Size of managed disk in GB.
echo "diskSizeGB=${diskSizeGB}"
# Skip a line
echo

# Authenticate to subscription
az login

# Select subscription
echo "Selecting subscription ${sub}"
az account set --subscription $sub
# Get storage account name
sa="$(az storage account list --resource-group $resourceGroup --query [*].[name] --output tsv)"
# Get first encyrption key for storage account
k1="$(az storage account keys list --resource-group $resourceGroup \
--account-name $sa \
--query "[?contains(keyName,'key1')].[value]" \
--output tsv)"

# Construct blobUrl from storage account name, container and blob name.
blobUrl="https://$sa.blob.core.windows.net/$container/$blobName"

# Create new storage container
az storage container create --account-name $sa \
--name $container

# Upload customized *.vhd from on premisses local or shared file system, to Azure blob storage to stage for deployment
az storage blob upload --account-name $sa \
--account-key $k1 \
--container-name $container \
--type $blobType \
--file $vhdSource \
--name $blobName

# Create a managed disk from the uploaded VHD as the source.
az disk create \
--resource-group $resourceGroup \
--name $managedDiskName \
--location $location \
--size-gb $diskSizeGB \
--sku $storageSku \
--source $blobUrl

# Create a public IP address resource
az network public-ip create --resource-group --name $vmPip

# Create a network interface and associate with public ip addres $vmPip
az network nic create --resource-group $resourceGroup --vnet-name $vNetName --subnet $subnetName --name $vmNic --public-ip-address $vmPip

# Create a VM from the managed disk.
az vm create --resource-group $resourceGroup \
--location $location \
--name $machineName \
--availability-set $avSet \
--size $vmSize \
--tags $tag \
--nics $vmNic \
--os-type $os \
--attach-os-disk $managedDiskName
