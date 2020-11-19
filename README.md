# Stop-Start-AzureVMs (Scheduled VM Shutdown/Startup)
This PowerShell Workflow runbook connects to Azure using an Automation Credential and Starts/Stops a VM/a list of VMs/All VMs in a Subscription in-parallel. 
You can attach a recurring schedule to this runbook to run it at a specific time.

## This script is using following contribution:
https://gallery.technet.microsoft.com/scriptcenter/Stop-Start-AzureVM-535c2414

## The switch disk part that has been added to above contribution is described here:
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/convert-disk-storage 

# REQUIRED
1. SubscriptionId - parameter that allows scoping VMs to a particular  Subscription.
2. AzureVMList - parameter to input the VM/VMList Name - seperated by (,).
3. Action - Parameter to perform the action. Stop - to stop the Azure Virtual Machine; Start - to start the Azure Virtual Machine.
4. Optional: Disktype in Stop and Start modus can be adapted. Default: Stop: Standard_LRS, Start: Premium_LRS.

# NOTES:
1. AzureCredential - Is added as an credential under Shared Resources at the Automation Account level.



