param(
    [string]$OutputDirectory = 'C:\temp',
    [ValidateSet('Csv', 'Json', 'Both')]
    [string]$OutputFormat = 'Csv'
)

$ErrorActionPreference = 'Stop'
$script:HadErrors = $false
$script:LogFile = $null

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
    $services = @(Get-Service | Select-Object Name, DisplayName, Status, StartType)
    $groups = @{
        'services_running' = @($services | Where-Object { $_.Status -eq 'Running' })
        'services_not_running' = @($services | Where-Object { $_.Status -ne 'Running' })
    }

    foreach ($name in $groups.Keys) {
        $items = @($groups[$name])
        if ($OutputFormat -in @('Csv', 'Both')) {
            $path = Join-Path $OutputDirectory "$name.csv"
            $items | Select-Object Name, DisplayName, Status, StartType |
                Export-Csv -LiteralPath $path -Delimiter ';' -NoTypeInformation -Encoding UTF8
            Write-Log "Exported $($items.Count) services to $path"
        }

        if ($OutputFormat -in @('Json', 'Both')) {
            $path = Join-Path $OutputDirectory "$name.json"
            $json = ConvertTo-Json -InputObject $items -Depth 3
            Set-Content -LiteralPath $path -Value $json -Encoding UTF8
            Write-Log "Exported $($items.Count) services to $path"
        }
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
                'stop'    { Stop-Service -InputObject $service -ErrorAction Stop }
                'restart' { Restart-Service -InputObject $service -ErrorAction Stop }
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
