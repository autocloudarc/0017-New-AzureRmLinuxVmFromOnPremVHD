## DESCRIPTION
This Linux shell script will upload a previously prepared specilized *.vhd Virtual Machine image from an on-premisses hypervisor to Azure, then deploy an Azure Linux VM from this *.vhd using commands from the Azure CLI.
A CentOS 7 VM was used to test this script, but other Linux distros can be used as well (see REFERENCES item 2 below).
For instructions on how to prepare a specialized Linux VM onpremises for Azure, please see REFERENCES item 2 also.

REQUIREMENTS
1. An Azure subscription. If you or your organization does not already have a subscription, start here: https://azure.microsoft.com/en-us/
2. An on-premises hypervisor. See REFERENCES items for more information.

ARGUMENTS <br>
-s Existing subscription in which uploaded specialized VM will be provisioned
. <br>
-v Existing source path for *.vhd file that will be uploaded to Azure blob storage. <br>
-r 
Existing resource group that contains all network storage and compute resources associated with this *.vhd specialized image
. <br>
-l Azure region associated with the existing resource group to which this image will be uploaded and provisioned. <br>
-c New Azure storage account container name that will be created by this script to host the uploaded *.vhd specialized image for the Azure VM. <br>
-m New Azure VM name that will be used when creating the new specialized VM in Azure. <br>
-a Existing availability set into which the new Azure VM will be placed for update and failure domain fault tolerance. <br>
-t One or more new space-separated arbitrary tags for the new Azure VM that will be deployed. <br>
-u Existing Azure subnet into which the new Azure VM will be deployed. <br>
-e Exisitng Azure virtual network that contains the target subnet (-u) above. <br>
-z New disk size in GB of managed disk for new Azure VM. <br>

EXAMPLE <br>
New-AzureRmLinuxVmFromOnPremVHD.sh -s 'MySubscription' -v '/mnt/d/vhd/MyOnPremVmImageForAzure.vhd' -r 'myResourceGroup' -l 'eastus2' -c 'containerforvhd'-m 'myVmName' -a 'MyAvilabilitySet' -t 'distro=CentOS7' -u 'MySubnetName'-e 'MyVnetName' -z 32

SYNTAX    	
New-AzureRmLinuxVmFromOnPremVHD.sh -s subscription -v vhdSource -r resourceGroup -l location -c container -m machineName -a avSet 
-t tag -u subnetName -e vNetName -z diskSizeGB

REFERENCES
1. https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-centos
2. https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-generic
3. https://docs.microsoft.com/en-us/azure/virtual-machines/linux/upload-vhd

4. https://github.com/paulomarquesc/AzureCLI2.0BashDeployment/blob/master/azuredeploy.sh
#
5. https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/

**FEEDBACK**
Feel free to ask questions, provide feedback, contribute, file issues, etc. so we can make this even better!
