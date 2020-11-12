<#
See this link for the Stop/Start part:
https://ms.portal.azure.com/#create/Microsoft.StartStopVMSolution
https://gallery.technet.microsoft.com/scriptcenter/Stop-Start-AzureVM-535c2414 

See this link for the switch disk SKU part:
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/convert-disk-storage

Besides following links are helpful:
https://docs.microsoft.com/en-us/powershell/module/azurerm.compute/new-azurermdiskupdateconfig?view=azurermps-6.13.0
https://docs.microsoft.com/en-us/azure/automation/troubleshoot/runbooks (why using "InlineScript")
https://docs.microsoft.com/de-de/system-center/sma/overview-powershell-workflows?view=sc-sma-2019
#>

Workflow Stop-Start-AzureVM 
{ 
    Param 
    (    
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $AzureSubscriptionId="1234567c-9f94-9f9b-999c-bbb12345y12d", 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $AzureVMList="sapdemoides", 
        [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
        [String] 
        $Action="Start",
        [Parameter(Mandatory=$true)][ValidateSet("Premium_LRS","Standard_LRS","StandardSSD_LRS","UltraSSD_LRS")] 
        [String] 
        $DiskTypeStopped="Standard_LRS",
        [Parameter(Mandatory=$true)][ValidateSet("Standard_LRS","Premium_LRS","StandardSSD_LRS","UltraSSD_LRS")] 
        [String] 
        $DiskTypeStarted="Premium_LRS"
    ) 

    "Loging in to Azure ..."
    $runAsConnectionProfile = Get-AutomationConnection -Name "AzureRunAsConnection"
    Add-AzureRmAccount -ServicePrincipal -TenantId $runAsConnectionProfile.TenantId `
    -ApplicationId $runAsConnectionProfile.ApplicationId `
    -CertificateThumbprint $runAsConnectionProfile.CertificateThumbprint 
    
    Write-Output "Authenticated with Automation Run As Account."
    Select-AzureRmSubscription -SubscriptionId $AzureSubscriptionId
 
    if($AzureVMList -ne "All") 
    { 
        $AzureVMs = $AzureVMList.Split(",") 
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
    } 
    else 
    { 
        $AzureVMs = (Get-AzureRmVM).Name 
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
 
    } 
 
    foreach($AzureVM in $AzureVMsToHandle) 
    { 
        if(!(Get-AzureRmVM | ? {$_.Name -eq $AzureVM})) 
        { 
            throw " AzureVM : [$AzureVM] - Does not exist! - Check your inputs " 
        } 
    } 
 
    if($Action -eq "Stop") 
    { 
        Write-Output "Stopping VMs"; 
        foreach ($AzureVM in $AzureVMsToHandle) 
        { 
            Get-AzureRmVM | ? {$_.Name -eq $AzureVM} | Stop-AzureRmVM -Force 
            Write-Output "Switching all disks to $DiskTypeStopped to reduce costs during off-times ..."; 
            $vmResource = Get-AzureRmResource -Name $AzureVM
            $vmDisks = Get-AzureRmDisk -ResourceGroupName $vmResource.ResourceGroupName 
            $vm = Get-AzureRmVM -Name $AzureVM -resourceGroupName $vmResource.ResourceGroupName
            foreach ($disk in $vmDisks)
                {
	            if ($disk.ManagedBy -eq $vm.Id)
                    # only change the disks attached to the relevant VM
	                {
                    InlineScript {
                        $diskupdateconfig = New-AzureRmDiskUpdateConfig -SkuName $using:DiskTypeStopped 
		                Update-AzureRMDisk -ResourceGroupName $using:vmResource.ResourceGroupName -DiskName $using:disk.Name -DiskUpdate $diskupdateconfig
                       } 
                    }
                }
        }
	}
    else 
    { 
        Write-Output "Starting VMs"; 
        foreach ($AzureVM in $AzureVMsToHandle) 
        { 
            Write-Output "Switching all disks to $DiskTypeStarted to improve performance ..."; 
            $vmResource = Get-AzureRmResource -Name $AzureVM
            $vmDisks = Get-AzureRmDisk -ResourceGroupName $vmResource.ResourceGroupName 
            $vm = Get-AzureRmVM -Name $AzureVM -resourceGroupName $vmResource.ResourceGroupName
            foreach ($disk in $vmDisks)
                {
	            if ($disk.ManagedBy -eq $vm.Id)
                    # only change the disks attached to the relevant VM
	                {
                    InlineScript { 
                        $diskupdateconfig = New-AzureRmDiskUpdateConfig -SkuName $using:DiskTypeStarted
		                Update-AzureRMDisk -ResourceGroupName $using:vmResource.ResourceGroupName -DiskName $using:disk.Name -DiskUpdate $diskupdateconfig
                        }
                    }
                }
            Get-AzureRmVM | ? {$_.Name -eq $AzureVM} | Start-AzureRmVM 
            
        } 
    } 
}