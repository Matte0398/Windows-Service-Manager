# Windows Service Manager

An interactive PowerShell utility for managing local Windows services and exporting service information to CSV or JSON reports.

The script allows users to start, stop, restart and configure Windows services through a simple command-line interface. It also provides diagnostic logging to track operations and errors.

## Contents

- [Features](#features)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Usage](#usage)
- [Interactive Actions](#interactive-actions)
- [Reports and Examples](#reports-and-examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- Start, stop and restart local Windows services.
- Change service startup types (`Automatic`, `Manual`, `Disabled`).
- Select services by internal `Name` or `DisplayName`.
- Export service information to CSV, JSON or both formats.
- Record operations, warnings and errors in a diagnostic log.
- Support forced stop and restart operations when required.

## Repository Structure

```text
Windows-Service-Manager/
├── Manage-WindowsService.ps1
├── README.md
├── LICENSE
└── examples/
    ├── service_manager.log
    ├── services.csv
    └── services.json
```

## Requirements

- Windows operating system with PowerShell and built-in service cmdlets.
- An interactive PowerShell terminal.
- Write permissions for the selected output directory.
- Administrator privileges for service operations that require elevation.

No additional PowerShell modules are required.

**Note:** Run PowerShell as Administrator when modifying services. Script execution must also be permitted by the applicable PowerShell execution policy.

## Usage

Clone the repository or download the PowerShell script, then open a PowerShell terminal in the project directory.

### Basic execution

```powershell
.\Manage-WindowsService.ps1
```

By default, the script exports service information in CSV format to `C:\temp`.

### Custom output directory and format

```powershell
.\Manage-WindowsService.ps1 -OutputDirectory 'C:\Reports\Services' -OutputFormat Both
```

### Enable forced operations

```powershell
.\Manage-WindowsService.ps1 -Force
```

### Display help

```powershell
.\Manage-WindowsService.ps1 -Help
```

### Available Parameters

| Parameter          | Default   | Description                                                       |
| ------------------ | --------- | ----------------------------------------------------------------- |
| `-OutputDirectory` | `C:\temp` | Directory for reports and logs. Created automatically if missing. |
| `-OutputFormat`    | `Csv`     | Report format: `Csv`, `Json` or `Both`.                           |
| `-Force`           | Disabled  | Enables forced stop and restart operations.                       |
| `-Help`, `-H`      | Disabled  | Displays usage information and exits.                             |

### Execution Flow

1. The script initializes the output directory and diagnostic log.
2. The user is prompted to confirm execution by entering `y`.
3. An initial snapshot of local Windows services is exported.
4. The interactive menu allows the user to manage services.
5. Selecting `0` exits the menu and generates a final service report.

The final export overwrites existing reports of the selected format, ensuring they reflect the service state at the end of the session.

If the initial prompt is declined, execution ends without exporting services, although the output directory and log may already have been created.

## Interactive Actions

Once execution is confirmed, the following actions are available:

| Action      | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `start`     | Start a selected service.                                       |
| `stop`      | Stop a selected service.                                        |
| `restart`   | Restart a selected service.                                     |
| `starttype` | Change the startup type to `Automatic`, `Manual` or `Disabled`. |
| `0`         | Exit the menu and export the final service snapshot.            |

Services can be selected using their internal `Name` or an unambiguous `DisplayName`.

After each successful operation, the script retrieves the updated service information and logs its previous and current status along with its startup type.

**Important notes:**

- Only local Windows services are supported.
- Changing the startup type does not automatically start or stop the service.
- Operations are performed without an additional confirmation prompt.
- The `-Force` parameter may also stop dependent services. These services are not automatically restored to their previous state.
- Forced operations do not bypass Windows permissions or service restrictions.

## Reports and Examples

The script generates reports and a diagnostic log in the configured output directory.

| File                  | Description                                                             |
| --------------------- | ----------------------------------------------------------------------- |
| `services.csv`        | Service inventory in semicolon-separated UTF-8 CSV format.              |
| `services.json`       | Service inventory as a UTF-8 JSON array.                                |
| `service_manager.log` | Timestamped diagnostic messages with `INFO`, `WARN` and `ERROR` levels. |

Both report formats contain the following fields:

| Field         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `Name`        | Internal Windows service name.                          |
| `DisplayName` | User-friendly service name.                             |
| `Status`      | Current service status, such as `Running` or `Stopped`. |
| `StartType`   | Configured service startup type.                        |

The diagnostic log records script initialization, exports, service operations, warnings and errors. Existing log entries are preserved across executions.

### Example Output Files

Sample files are available in the [examples](examples/) directory:

- [CSV Report](examples/services.csv)
- [JSON Report](examples/services.json)
- [Diagnostic Log](examples/service_manager.log)

These examples demonstrate the generated file formats without requiring the script to be executed.

## Troubleshooting

| Issue                                  | Possible Solution                                                                       |
| -------------------------------------- | --------------------------------------------------------------------------------------- |
| Access denied                          | Run PowerShell as Administrator and verify service permissions.                         |
| Service not found or ambiguous         | Use the exact internal service `Name` from the exported report.                         |
| Service cannot be stopped or restarted | Check dependent services and consider `-Force` only when appropriate.                   |
| Invalid startup type                   | Use `Automatic`, `Manual` or `Disabled`.                                                |
| Report export fails                    | Verify directory permissions, available disk space and whether output files are locked. |
| Report contains outdated information   | Verify that the final export succeeded and review the diagnostic log.                   |
| Log write failure                      | Check output directory permissions and any console warnings.                            |

## License

This project is released under the MIT License. See the [LICENSE](LICENSE) file for details.
