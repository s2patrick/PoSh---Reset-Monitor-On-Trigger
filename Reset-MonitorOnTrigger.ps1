<#
.SYNOPSIS
Resets the state of a monitor when the corresponding alert has been closed.

Author: Patrick Seidl
(C) Syliance IT Services GmbH

.DESCRIPTION
Usually this PS is triggered by a SCOM notification when an alert has been closed by an user. A notification channel, subscriber and subscription must be configured.

Don't forget to distribute the PS to all MS (Notification Resource Pool) or give acces to the script.

.PARAMETER AlertId
The alert ID of the closed alert.

.PARAMETER Debug
Whether a event should be written to the event log or not. By default, this parameter is overwritten in the PS itself.

.EXAMPLE
How the notification channel must be configured:

NAME:
Reset-MonitorOnTrigger_OM12

DESCRIPTION:
Resets the monitor when the corresponding alert has been closed by an user.

SETTINGS:
C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe
-Command "& '"C:\SCOM\Scripts\Reset-MonitorOnTrigger_OM12.ps1"'" -AlertId '$Data/Context/DataItem/AlertId$'
C:\Windows\system32\WindowsPowerShell\v1.0

 .EXAMPLE
How the notification subscriber must be configured:

NAME:
Reset-MonitorOnTrigger_OM12

ADDRESS NAME:
Reset-MonitorOnTrigger_OM12

.EXAMPLE
How the notification subscriber must be configured:

NAME:
Reset-MonitorOnTrigger_OM12

DESCRIPTION:
Resets the monitor when the corresponding alert has been closed by an user.

CRITERIA:
Notify on all alerts where 
 with Closed (255) resolution state
 and resolved by %\% user  

 .NOTES
 Don't forget to distribute the PS to all MS (Notification Resource Pool) or give acces to the script.

 Change the Import-Module routine for SCOM 2012 SP1.
 
#>

param(
    [string]$AlertId,
    [bool]$Debug 
)

#$Debug=$true

if ($Debug -eq $true) {
    # Load Script API for Event Logging
    $objApi = new-object -comObject "MOM.ScriptAPI"
    $objAPI.LogScriptEvent("Reset-MonitorOnTrigger.ps1", 660, 4, "Try to reset Health State for
    Id: $AlertId
    MS: " + (hostname) + "
    ")
}

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.EnterpriseManagement.OperationsManager.Common") | Out-Null  
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.Core') | Out-Null  
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.OperationsManager') | Out-Null  
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.Runtime') | Out-Null  

$mgConnSetting = New-Object Microsoft.EnterpriseManagement.ManagementGroupConnectionSettings($env:computername)  
$mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup($mgConnSetting)

# Receive alert information
$Alert = $mg.GetMonitoringAlert($AlertId)

if ($Alert.IsMonitorAlert -eq $true) {
    write-host "Raised from a monitor"
    # Get Objects
    $Monitor = $mg.GetMonitor($Alert.MonitoringRuleId.Guid)
    $MonitoringClass = $mg.GetMonitoringClass($Alert.MonitoringClassId.Guid)
    $MonitoringObject = $mg.GetMonitoringObject($Alert.MonitoringObjectId)
    # Reset Monitor
    $MonitoringObject | foreach {$_.ResetMonitoringState($Monitor)} | Out-Null
    # if debug is true then write diagnostic end event
    if ($Debug -eq $true) {
        $objAPI.LogScriptEvent("Reset-MonitorOnTrigger.ps1", 661, 4, "Reset Health State for
        Id: $AlertId
        Name: " + $Alert.Name + "
        MS: " + (hostname) + "
    
        Please verify the successful change in the console.
        ")
    }
} else {
    if ($Alert.Name) {
        # if debug is true then write diagnostic end event
        if ($Debug -eq $true) {
            write-host "Not raised from a monitor"
            $objAPI.LogScriptEvent("Reset-MonitorOnTrigger.ps1", 662, 4, "Not raised from a Monitor:
            Id: $AlertId
            Name: " + $Alert.Name + "
            MS: " + (hostname) + "
    
            IsMonitorAlert: " + $Alert.IsMonitorAlert)
        }
    } else {
        write-host "Could not retrieve alert data"
        $objAPI.LogScriptEvent("Reset-MonitorOnTrigger.ps1", 663, 2, "Could not retrieve alert data for
        Id: $AlertId
        Name: " + $Alert.Name + "
        MS: " + (hostname) + "
        ")
    }

}
