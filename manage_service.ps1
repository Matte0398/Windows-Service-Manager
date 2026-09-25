#######################################################################
## Description: Script for managing services on your Windows system
##
## Author: Matteo Z.
#######################################################################

function print_usage {
	Write-Host -ForegroundColor "red" "`nDescription:"
	Write-Host "   Script for managing services on your Windows system (such as getting the list of services, restarting them or stopping them)"
    Write-Host "   To avoid errors when performing stop or restart services, it is recommended to run the script as administrator"
	Write-Host "`n   File created witih the list of the running services: $file_svc_ok"
	Write-Host "`n   File created with the list of other services excluding running services: $file_svc_ko`n"
}

function verify_svc_files {
    foreach ($item in $files) {
        if (Test-Path -LiteralPath $item -PathType Leaf) {
            Clear-Content $item
        }
    }
}

function create_svc_files {
    $get_svc |
        Where-Object { $_.Status -eq "Running" } |
        Export-Csv -LiteralPath $file_svc_ok -Delimiter ";" -NoTypeInformation -Encoding UTF8

    $get_svc |
        Where-Object { $_.Status -ne "Running" } |
        Export-Csv -LiteralPath $file_svc_ko -Delimiter ";" -NoTypeInformation -Encoding UTF8

    Write-Host "Running services can be found in: $file_svc_ok"
    Write-Host "Other services can be found in: $file_svc_ko"
}

function svc_existence {
    $flag = 0

    foreach ($item in $get_svc) {
        if ($item.'Name' -eq $user_input -or $item.'DisplayName' -eq $user_input) {
            $flag = 1
        }
    }

    return $flag
}


########## MAIN ##########

$dir = "C:\temp"
$file_svc_ok = $dir + "\services_running.csv"
$file_svc_ko = $dir + "\services_not_running.csv"
$files = @($file_svc_ok, $file_svc_ko)

if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
    Write-Host "The directory $dir does not exist! Create it before running the script!"
    exit 1
}

print_usage
Start-Sleep -Seconds 2.0        # it suspends the activity in a script or session for the specified period of time

$user_input = Read-Host "Do you want to continue with the program? (y/n)"

if ($user_input -eq "y") {
    $get_svc = Get-Service | Select-Object Name, DisplayName, Status, StartType
    verify_svc_files
    create_svc_files

    while ($true) {
        $user_input = Read-Host "`nDo you want restart a service or stop its? (restart/stop) - type 0 to quit"

        if ($user_input -eq "restart") {
            $user_input = Read-Host "Type the service you want to restart"
            $flag = svc_existence

            if ($flag) {
                Get-Service $user_input | Restart-Service
            } else {
                Write-Host "Service not found!"
            }
        } elseif ($user_input -eq "stop") {
            $user_input = Read-Host "Type the service you want to stop"
            $flag = svc_existence

            if ($flag) {
                Get-Service $user_input | Stop-Service
            } else {
                Write-Host "Service not found!"
            }
        } elseif ($user_input -eq 0) {
            break
        }
    }
} else {
    Write-Host "Exit from the program!"
}

Write-Host ""