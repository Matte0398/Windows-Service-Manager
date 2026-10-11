########################################################################################
## Description: Manage local Windows services and export CSV or JSON service reports
##
## Author: Matteo Z.
########################################################################################

[CmdletBinding()]
param(
    [string]$OutputDirectory = 'C:\temp',
    [ValidateSet('Csv', 'Json', 'Both')]
    [string]$OutputFormat = 'Csv',
    [switch]$Force,
    [Alias('H')]
    [switch]$Help
)


function Show-Usage {
    Write-Output @'
Usage:
  .\Manage-WindowsService.ps1 [-OutputDirectory <DIRECTORY>] [-OutputFormat <Csv|Json|Both>]
  .\Manage-WindowsService.ps1 -Help

Parameters:
  -OutputDirectory   Report and log directory; default: C:\temp.
                     Created automatically if missing.
  -OutputFormat      Csv (default), Json or Both. Existing reports are overwritten.
  -Force    Allow stop/restart operations when dependent services exist.
  -Help, -H          Display usage without creating files or changing services.

Interactive actions:
  start              Start a service.
  stop               Stop a service.
  restart            Restart a service.
  starttype          Set Automatic, Manual or Disabled startup type.
  0                  Exit the action menu.

Enter y at the initial prompt to export services and open the action menu.
Services can be selected by Name or an unambiguous DisplayName.
Reports are exported before and after the action loop.
The diagnostic log is appended to service_manager.log in the output directory.
Use an elevated PowerShell session to change services.

Examples:
  .\Manage-WindowsService.ps1
  .\Manage-WindowsService.ps1 -OutputDirectory 'C:\Reports\Services' -OutputFormat Both
'@
}


function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'ERROR', 'WARN')]
        [string]$Level = 'INFO'
    )

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line

    if ($script:LogFile) {
        try {
            Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
        } catch {
            $script:HadErrors = $true
            Write-Warning "Could not write log file: $($_.Exception.Message)"
        }
    }
}


function Export-ServiceSnapshot {
    $services = @(
        Get-Service |
            Select-Object Name, DisplayName,
                @{Name = 'Status'; Expression = { [string]$_.Status }},
                @{Name = 'StartType'; Expression = { [string]$_.StartType }}
    )

    if ($OutputFormat -in @('Csv', 'Both')) {
        $csvPath = Join-Path $OutputDirectory 'services.csv'

        $services |
            Export-Csv -LiteralPath $csvPath -Delimiter ';' `
                -NoTypeInformation -Encoding UTF8

        Write-Log "Exported $($services.Count) services to $csvPath"
    }

    if ($OutputFormat -in @('Json', 'Both')) {
        $jsonPath = Join-Path $OutputDirectory 'services.json'
        $servicesJson = ConvertTo-Json -InputObject $services -Depth 3

        Set-Content -LiteralPath $jsonPath -Value $servicesJson -Encoding UTF8
        Write-Log "Exported $($services.Count) services to $jsonPath"
    }
}


function Resolve-Service {
    param([string]$ServiceName)

    $matches = @(Get-Service | Where-Object {
        $_.Name -eq $ServiceName -or $_.DisplayName -eq $ServiceName
    })

    if ($matches.Count -eq 0) {
        throw "Service '$ServiceName' was not found."
    }

    if ($matches.Count -gt 1) {
        throw "Service name '$ServiceName' is ambiguous. Use the internal service Name."
    }

    return $matches[0]
}


########## MAIN ##########

if ($Help) {
    Show-Usage
    exit 0
}

$ErrorActionPreference = 'Stop'
$script:HadErrors = $false
$script:LogFile = $null

try {
    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }

    $script:LogFile = Join-Path $OutputDirectory 'service_manager.log'
    Write-Log "Windows Service Manager started (format: $OutputFormat)."
    Write-Log 'Use an elevated PowerShell session to change services.'
} catch {
    Write-Host "Initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try {
    $answer = Read-Host 'Continue and export local services? (y/n)'

    if ($answer -ne 'y') {
        Write-Log 'Cancelled by user.'
        exit 0
    }

    try {
        Export-ServiceSnapshot
    } catch {
        $script:HadErrors = $true
        Write-Log "Initial export failed: $($_.Exception.Message)" 'ERROR'
    }

    while ($true) {
        Write-Host ''
        $action = (Read-Host 'Action (start/stop/restart/starttype/0 to exit)').Trim().ToLowerInvariant()

        if ($action -eq '0') { break }

        if ($action -notin @('start', 'stop', 'restart', 'starttype')) {
            Write-Log "Unknown action '$action'." 'WARN'
            continue
        }

        $serviceName = (Read-Host 'Service Name or DisplayName').Trim()

        try {
            $service = Resolve-Service -ServiceName $serviceName
            $before = "$($service.Status)"

            switch ($action) {
                'start'   { Start-Service -InputObject $service -ErrorAction Stop }
                'stop'    { Stop-Service -InputObject $service -Force:$Force -ErrorAction Stop }
                'restart' { Restart-Service -InputObject $service -Force:$Force -ErrorAction Stop }
                'starttype' {
                    $startType = (Read-Host 'Startup type (Automatic/Manual/Disabled)').Trim()
                    
                    if ($startType -notin @('Automatic', 'Manual', 'Disabled')) {
                        throw "Invalid startup type '$startType'."
                    }

                    Set-Service -Name $service.Name -StartupType $startType -ErrorAction Stop
                }
            }

            $updated = Get-Service -Name $service.Name -ErrorAction Stop
            Write-Log "$action succeeded for '$($service.Name)' (before: $before; after: $($updated.Status); startup: $($updated.StartType))."
        } catch {
            $script:HadErrors = $true
            Write-Log "$action failed for '$serviceName': $($_.Exception.Message)" 'ERROR'
        }
    }

    try {
        Export-ServiceSnapshot
    } catch {
        $script:HadErrors = $true
        Write-Log "Final export failed: $($_.Exception.Message)" 'ERROR'
    }
} catch {
    $script:HadErrors = $true
    Write-Log "Unexpected execution error: $($_.Exception.Message)" 'ERROR'
}

if ($script:HadErrors) {
    Write-Log 'Completed with errors. Check the log.' 'WARN'
    exit 1
}

Write-Log 'Completed successfully.'
exit 0