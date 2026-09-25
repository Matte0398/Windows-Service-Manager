# Windows Service Manager

An interactive PowerShell script for exporting Windows service information and stopping or restarting a selected service.

**Run PowerShell as Administrator before using this program** to avoid permission-related errors.

## Features

- Export service names, display names, statuses and startup types to CSV.
- Save running and non-running services in separate files.
- Stop or restart a service by entering its name at the prompt.

## Requirements

- Windows with PowerShell available.
- Administrator privileges for stopping or restarting services.
- A writable `C:\temp` directory. The script stops if this directory does not exist.

The script uses built-in PowerShell cmdlets; no additional modules need to be installed.

## Usage

1. Open the Start menu, search for **PowerShell**, select **Run as administrator** (or **Esegui come amministratore**) and accept the elevation prompt.
2. Navigate to the directory containing `manage_service.ps1`.
3. Create the output directory if it does not already exist:

   ```powershell
   New-Item -ItemType Directory -Path C:\temp -Force
   ```

4. Run the script:

   ```powershell
   powershell.exe .\manage_service.ps1
   ```

5. Enter `y` to continue and export the service lists.
6. Enter `stop` or `restart`, then provide the service's **Name** from the exported files, such as `Spooler`. Use the `Name` column rather than `DisplayName`.
7. Enter `0` at the action prompt to exit.

## Output files

| File                               | Contents                                         |
| ---------------------------------- | ------------------------------------------------ |
| `C:\temp\services_running.csv`     | Services with status `Running`.                  |
| `C:\temp\services_not_running.csv` | All services with a status other than `Running`. |

Both files are exported in UTF-8 with a semicolon (`;`) delimiter and the columns `Name`, `DisplayName`, `Status` and `StartType`. When importing them into a spreadsheet, select `;` as the separator.

Example row:

```csv
"Name";"DisplayName";"Status";"StartType"
"Spooler";"Print Spooler";"Running";"Automatic"
```

The files are overwritten whenever you enter `y` to continue. They represent the service states at export time and are not refreshed after stop or restart operations.

## Example files

The [examples](examples/) folder contains sample exports showing the format and content of the generated CSV files:

| File                                                          | Contents                                            |
| ------------------------------------------------------------- | --------------------------------------------------- |
| [services_running.csv](examples/services_running.csv)         | Sample services with status `Running`.              |
| [services_not_running.csv](examples/services_not_running.csv) | Sample services with a status other than `Running`. |

Service names, display names and states reflect the system used to create the samples; your results may differ. Each execution writes its own exports to `C:\temp`.

## Troubleshooting

### PowerShell was not opened as Administrator

If you try to stop a service without sufficient privileges, you may see an error like this on an Italian-language Windows installation:

```text
Stop-Service : Impossibile arrestare il servizio 'Servizio di gestione dell'accesso alle funzionalità (camsvc)'
```

Close the current PowerShell window, reopen it with **Run as administrator** (**Esegui come amministratore**) and run the script again from its directory. Restart operations can also fail when the session lacks the required permissions.

This message alone does not identify the cause. If it persists in an elevated session, check the complete error details, service dependencies and any restrictions on stopping that service.

### Output directory not found

If `C:\temp` does not exist, the script displays the following message and exits before exporting any files:

```text
The directory C:\temp does not exist! Create it before running the script!
```

Create the directory using the command in the usage instructions, then rerun the script.

### Service not found

Copy the internal service name from the `Name` column of an exported file and retry. The script takes its service list when you enter `y`; rerun it if a service was installed afterward.
