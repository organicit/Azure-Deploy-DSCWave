<#
  Author: Trevor Sullivan <pcgeek86@gmail.com>
  Description: Creates a new Microsoft Azure Virtual Machine, and automatically
               deploys the Microsoft DSC Resource Kit Wave 6 to it. To use this
               script, update the variables, such as: Affinity Group name, Cloud
               Service name, Virtual Machine name, Azure Subscription name, VM
               role size, and which VM image you want to use.
               
               For more information, watch this video: https://www.youtube.com/watch?v=Az8pmHt-EbA
               Blog post: http://trevorsullivan.net/2014/08/21/use-powershell-dsc-to-install-dsc-resources/
#>

#region Subscription
$SubscriptionName = 'Visual Studio Ultimate with MSDN';
Select-AzureSubscription -SubscriptionName $SubscriptionName;
#endregion

#region Affinity Group
$AffinityGroup = @{
    Name = 'powershelldsc';
    Location = 'North Central US';
    };
if (!(Get-AzureAffinityGroup -Name $AffinityGroup.Name -ErrorAction SilentlyContinue)) {
    [void](New-AzureAffinityGroup @AffinityGroup);
}
Read-Host -Prompt '#Region Affinity Group completed!';
#endregion

#region Storage Account
$StorageAccount = @{
    StorageAccountName = 'powershelldsc';
    AffinityGroup = $AffinityGroup.Name;
    }
if (!(Get-AzureStorageAccount -StorageAccountName $StorageAccount.StorageAccountName -ErrorAction SilentlyContinue)) {
    [void](New-AzureStorageAccount @StorageAccount);
}

Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccountName $StorageAccount.StorageAccountName;
# Get the storage account keys, and then create a storage context
$StorageKey = Get-AzureStorageKey -StorageAccountName $StorageAccount.StorageAccountName;
$Context = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $StorageKey.Primary;
Read-Host -Prompt '#Region Storage Account completed!';
#endregion

#region DSC Configuration
$DSCConfig = @{
    ConfigurationPath = '{0}\DSC-DSCWave.ps1' -f $PSScriptRoot;
    ConfigurationArchive = '{0}\DSC-DSCWave.zip' -f $PSScriptRoot;
    }
Publish-AzureVMDscConfiguration -ConfigurationPath $DSCConfig.ConfigurationPath -ConfigurationArchivePath $DSCConfig.ConfigurationArchive -Force;
Publish-AzureVMDscConfiguration -ConfigurationPath $DSCConfig.ConfigurationPath -StorageContext $Context -Force;
Read-Host -Prompt '#Region DSC Configuration completed!';
#endregion

#region Cloud Service
$Service = @{
    ServiceName = 'powershelldsc';
    AffinityGroup = $AffinityGroup.Name;
    Description = 'Contains VMs used for PowerShell DSC testing.';
    };
if (!(Get-AzureService -ServiceName $Service.ServiceName -ErrorAction SilentlyContinue)) {
    [void](New-AzureService @Service);
}
Read-Host -Prompt '#Region Cloud Service completed!';
#endregion

#region Virtual Machine
#$ImageList = Get-AzureVMImage;
#$ImageList.Where({ $PSItem.ImageName -match '2012-R2' }).ImageName;
$VMConfig = @{
    Name = 'powershelldsc';
    InstanceSize = 'Medium';
    ImageName = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201407.01-en.us-127GB.vhd';
    };

# Create the VM configuration
$VM = New-AzureVMConfig @VMConfig;

$VMProvisioningConfig = @{
    Windows = $true;
    Password = 'P@ssw0rd!';
    AdminUsername = 'Trevor';
    VM = $VM;
    };

# Add the Windows provisioning details to the VM configuration
[void](Add-AzureProvisioningConfig @VMProvisioningConfig);

$VMDscExtension = @{
    ConfigurationArchive = '{0}.zip' -f (Split-Path -Path $DSCConfig.ConfigurationPath -Leaf);
    ConfigurationName = 'DSCWave';
    VM = $VM;
    };

[void](Set-AzureVMDscExtension @VMDscExtension);

# Create the Azure Virtual Machine
[void](New-AzureVM -ServiceName $Service.ServiceName -VMs $VM);
Write-Host -Object '#Region Virtual Machine completed!';
return;
#endregion


#region Cleanup
# NOTE: Used to clean up Azure resources so the script can re-run from scratch
Remove-AzureService -ServiceName $Service.ServiceName -DeleteAll -Force;
Remove-AzureStorageAccount -StorageAccountName $StorageAccount.StorageAccountName;
Remove-AzureAffinityGroup -Name $AffinityGroup.Name;
#endregion

#region Helper stuff
# RDP into the Azure VM
Get-AzureRemoteDesktopFile -ServiceName $Service.ServiceName -Name $VMConfig.Name -Launch;

# Update the DSC extension on the target AzureVM
# NOTE: (shouldn't need to use this, if it deploys correctly the first time)
$AzureVM = Get-AzureVM -ServiceName $Service.ServiceName -Name $VMConfig.Name;
$AzureVMNew = Set-AzureVMDscExtension -VM $AzureVM -ConfigurationArchive $VMDscExtension.ConfigurationArchive -ConfigurationName VisualStudio2013Express;
$AzureVMNew | Update-AzureVM;

# Stop/start the VM (just to use on-demand)
$AzureVM | Stop-AzureVM -Force;
$AzureVM | Start-AzureVM;
$AzureVM | Update-AzureVM;
$AzureVM | Remove-AzureVM -DeleteVHD;
#endregion
