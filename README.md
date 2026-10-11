# Windows Service Manager

[Manage-WindowsService.ps1](Manage-WindowsService.ps1) is an interactive PowerShell utility for managing local Windows services and exporting their current state to a single CSV or JSON report. It records operations and errors in a diagnostic log.

## Contents

- [Requirements](#requirements)
- [Usage and parameters](#usage-and-parameters)
- [Interactive actions](#interactive-actions)
- [Reports and log](#reports-and-log)
- [Example files](#example-files)
- [Exit codes and troubleshooting](#exit-codes-and-troubleshooting)
- [License](#license)

## Requirements

- Windows with PowerShell and the built-in service cmdlets.
- An interactive terminal for answering prompts.
- Write access to the output directory, or permission to create it.
- An elevated PowerShell session with appropriate permissions to change services.

Run PowerShell as Administrator for service operations. Script execution must be allowed by the applicable execution policy. No additional modules are required.

## Usage and parameters

From the project directory:

```powershell
# Default CSV report in C:\temp
.\Manage-WindowsService.ps1

# Export both formats to a custom directory
.\Manage-WindowsService.ps1 -OutputDirectory 'C:\Reports\Services' -OutputFormat Both

# Enable forced stop/restart operations
.\Manage-WindowsService.ps1 -Force

# Display usage without creating files or changing services
.\Manage-WindowsService.ps1 -Help
```

| Parameter          | Default   | Purpose                                                            |
| ------------------ | --------- | ------------------------------------------------------------------ |
| `-OutputDirectory` | `C:\temp` | Directory for reports and log; created automatically if missing.   |
| `-OutputFormat`    | `Csv`     | `Csv`, `Json` or `Both`; selects report files, not console output. |
| `-Force`           | Off       | Passes `-Force` to stop/restart operations throughout the session. |
| `-Help`, `-H`      | Off       | Displays usage and exits before initialization.                    |

Execution without arguments opens the interactive program. At the initial prompt, enter `y` to export services and open the action menu. Any other response cancels; the output directory and startup log may already have been created.

## Interactive actions

| Action      | Behavior                                                  |
| ----------- | --------------------------------------------------------- |
| `start`     | Starts the selected service.                              |
| `stop`      | Stops the selected service.                               |
| `restart`   | Restarts the selected service.                            |
| `starttype` | Sets startup type to `Automatic`, `Manual` or `Disabled`. |
| `0`         | Leaves the menu and triggers the final export.            |

Select a service by its internal `Name` or an unambiguous `DisplayName`. The script resolves services afresh for each operation. If the name is missing or ambiguous, it logs an error and returns to the menu. Unknown actions produce a warning and repeat the prompt.

After a successful operation, the script queries the service again and logs its before/after status and current startup type. Changing startup type does not itself start or stop the service. Operations have no additional confirmation, and only local services are managed.

`-Force` allows stop/restart when dependent services exist and can also stop dependent services. It does not bypass permissions or all service restrictions. Dependent services are not explicitly restored to their previous state by this script; consider the impact before forcing operations on shared system services.

## Reports and log

Files are written under `-OutputDirectory`:

| File                  | When produced                          | Contents                                                             |
| --------------------- | -------------------------------------- | -------------------------------------------------------------------- |
| `services.csv`        | `Csv` or `Both`                        | All services in one semicolon-separated UTF-8 CSV.                   |
| `services.json`       | `Json` or `Both`                       | All services in one UTF-8 JSON array.                                |
| `service_manager.log` | Initialization and subsequent activity | Appended timestamped messages with `INFO`, `WARN` or `ERROR` levels. |

Both reports contain the same four fields:

| Field         | Meaning                                                  |
| ------------- | -------------------------------------------------------- |
| `Name`        | Internal service name.                                   |
| `DisplayName` | User-facing service name.                                |
| `Status`      | Current state, such as `Running`, `Stopped` or `Paused`. |
| `StartType`   | Configured startup type.                                 |

Example CSV row:

```csv
"Name";"DisplayName";"Status";"StartType"
"Spooler";"Print Spooler";"Running";"Automatic"
```

Existing reports in the selected format are overwritten, so a successful final export reflects the end-of-session snapshot.

## Example files

The [examples](examples/) folder contains:

| File                                                | Contents                                                                                   |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [services.csv](examples/services.csv)               | Combined sample inventory, including running and non-running services.                     |
| [services.json](examples/services.json)             | The same sample records as a JSON array.                                                   |
| [service_manager.log](examples/service_manager.log) | Illustrative session using `Both`, with exports, a restart, a warning and a failed lookup. |

## Exit codes and troubleshooting

| Code | Meaning                                                                             |
| ---- | ----------------------------------------------------------------------------------- |
| `0`  | Successful completion, initial cancellation or help.                                |
| `1`  | Initialization failure or completion with recorded operation, export or log errors. |

| Problem                                    | What to check                                                                                                 |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| Access denied during an operation          | Run elevated and verify account permissions and service restrictions.                                         |
| Stop/restart blocked by dependent services | Review dependencies; use `-Force` only when stopping them is acceptable.                                      |
| Service not found or ambiguous             | Use the exact internal `Name` from the report.                                                                |
| Initialization or export failure           | Output path, write permissions, available disk space and whether the report is locked by another application. |
| Report contains an earlier snapshot        | Check whether final export succeeded; inspect the log.                                                        |
| Log write failure                          | Console warning and log directory permissions.                                                                |
| Invalid startup type                       | Enter `Automatic`, `Manual` or `Disabled`.                                                                    |

Review `service_manager.log` when execution completes with errors.

## License

Released under the MIT License. See [LICENSE](LICENSE).
