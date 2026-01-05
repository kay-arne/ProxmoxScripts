# Proxmox NIC Monitoring Script

A Bash script designed to run on a Proxmox host (or any Linux system) to monitor network connectivity by pinging multiple sources. It provides circular logging and can optionally restart the network stack if connectivity is lost.

## Features

*   **Multi-Source Monitoring**: Checks multiple IP addresses (e.g., Public DNS, Gateway) to avoid false positives.
*   **Configurable Failure Logic**: Trigger action only if *ALL* sources fail or if *ANY* source fails.
*   **Circular Logging**: Prevents disk fill-up by automatically rotating the log file when it exceeds a set number of lines.
*   **Automated Recovery**: Can restart the network stack (`systemctl restart networking`) upon failure (disabled by default for safety).

## Installation

1.  Clone this repository or copy `monitor_nic.sh` to your server (e.g., `/usr/local/bin/monitor_nic.sh`).
2.  Make the script executable:
    ```bash
    chmod +x monitor_nic.sh
    ```

## Configuration

Open the script in a text editor to adjust the variables at the top:

*   **`MONITOR_SOURCES`**: Array of IPs to ping. Default: `("8.8.8.8" "1.1.1.1")`.
*   **`ACTION_ON_FAILURE`**: Set to `"restart"` to enable network restarting. Default is `"log_only"`.
*   **`FAILURE_CONDITION`**: Set to `"ALL"` (default) or `"ANY"`.
*   **`MAX_LOG_LINES`**: Max lines for the log file. Default: `1000`.

## Usage

### Manual Run
Run the script manually to test:
```bash
./monitor_nic.sh
```
Check the output in `monitor_nic.log`.

### Cronjob Setup (Recommended)
To run the script automatically (e.g., every 5 minutes):

1.  Edit the root crontab:
    ```bash
    crontab -e
    ```
2.  Add the following line (adjust path as needed):
    ```cron
    */5 * * * * /path/to/monitor_nic.sh
    ```

## Logs
Logs are written to `monitor_nic.log` in the same directory as the script (or the path configured in `LOG_FILE`).
