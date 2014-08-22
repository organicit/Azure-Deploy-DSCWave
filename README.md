Azure-Deploy-DSCWave
====================

This repository contains code to deploy the Microsoft DSC Resource Kit Wave 6 to new Microsoft Azure IaaS Virtual Machines.

There are two files to be aware of:

* `DSC-DSCWave.ps1` (contains the DSC configuration that installs the Microsoft DSC Resource Kit)
* `New-AzureVMWithDsc.ps1` (deploys a new Microsoft Azure Virtual Machine

Prerequisites
----------------

You must have the following in place, prior to running this script:

1. A valid Microsoft Azure Subscription
2. The Microsoft Azure PowerShell module must be installed
3. The Azure PowerShell module must be configured to point to your Azure Subscription(s)

Usage
------

To use the `New-AzureVMWithDsc.ps1` script, update the `HashTable` values for:

* Subscription Name
* Affinity Group
* Storage Account
* Cloud Service
* Virtual Machine

Once you have updated the properties for all of these Azure resources, you can go ahead and execute the script. I am not responsible for your use of this code, or the information contained within this code repository. By using this code, and associated documentation, you assume all risk for its use.
