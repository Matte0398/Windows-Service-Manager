# Windows Service Manager

Interactive PowerShell utility for listing, stopping and restarting Windows services.

**Run PowerShell as Administrator before using this program** to avoid permission-related errors.

## Features

- Export service names, display names, statuses and startup types.
- Save running and non-running services in separate files.
- Stop or restart a service from an interactive prompt.

## Use Cases

- Windows service troubleshooting
- Operational support
- Monitoring remediation tasks

## Requirements

- Windows with PowerShell available.
- Administrator privileges for stopping or restarting services.
- A writable `C:\temp` directory. The script uses this fixed output path and does not create the directory automatically.

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
6. Enter `stop` or `restart`, then provide the service's **Name** from the exported files, such as `Spooler`. Use the internal service name: the action commands do not reliably resolve display names.
7. Enter `0` at the action prompt to exit.

## Output files

| File                               | Contents                                         |
| ---------------------------------- | ------------------------------------------------ |
| `C:\temp\services_running.csv`     | Services with status `Running`.                  |
| `C:\temp\services_not_running.csv` | All services with a status other than `Running`. |

Both files contain the columns `Name`, `DisplayName`, `Status` and `StartType`. Despite the `.csv` extension, values are separated by tabs.

The files are overwritten whenever you enter `y` to continue. They represent the service states at export time and are not refreshed after stop or restart operations.

## Troubleshooting

### PowerShell was not opened as Administrator

If you try to stop a service without sufficient privileges, you may see an error like this on an Italian-language Windows installation:

```text
Stop-Service : Impossibile arrestare il servizio 'Servizio di gestione dell'accesso alle funzionalità (camsvc)'
```

Close the current PowerShell window, reopen it with **Run as administrator** (**Esegui come amministratore**) and run the script again from its directory. Restart operations can also fail when the session lacks the required permissions.

This message alone does not identify the cause. If it persists in an elevated session, check the complete error details, service dependencies and any restrictions on stopping that service.

### Output directory not found

If exporting the service lists fails because `C:\temp` does not exist, create it using the command in the usage instructions, then rerun the script.

### Service not found

Copy the internal service name from the `Name` column of an exported file and retry. The script takes its service list when you enter `y`; rerun it if a service was installed afterward.
