#!/bin/bash

# ==============================================================================
# Script Name: monitor_nic.sh
# Description: Monitors network connectivity by pinging multiple sources.
#              Logs results and optionally restarts the network stack on failure.
# Usage:       Add to crontab to run periodically (e.g., every 5 minutes).
# ==============================================================================

# --- Configuration ---

# Array of IP addresses or hostnames to ping.
# Recommendation: Use reliable public DNS servers or redundant internal gateways.
MONITOR_SOURCES=("8.8.8.8" "1.1.1.1")

# Full path to the log file.
LOG_FILE="./monitor_nic.log"

# Maximum lines to keep in the log file (Circular Logging).
MAX_LOG_LINES=1000

# Action to take when failure condition is met.
# Options: "restart" (restarts networking) or "log_only" (just logs the error).
ACTION_ON_FAILURE="log_only"

# Condition to trigger the action.
# Options: "ALL" (fail only if ALL sources are down) or "ANY" (fail if ANY source is down).
FAILURE_CONDITION="ALL"

# Command to restart the network stack. Adjust for your specific OS/Distro if needed.
# Common commands: "systemctl restart networking", "ifdown -a && ifup -a", etc.
RESTART_CMD="systemctl restart networking"

# --- Functions ---

# Function: log_message
# Description: Appends a timestamped message to the log file and handles rotation.
log_message() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"

    # Circular logging: Check line count and truncate if necessary
    if [ -f "$LOG_FILE" ]; then
        local line_count=$(wc -l < "$LOG_FILE")
        if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
            # Keep the last MAX_LOG_LINES lines. 
            # Using a temp file is safer to avoid race conditions or data loss during write.
            tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
        fi
    fi
}

# Function: check_connectivity
# Description: Pings monitor sources and determines overall status.
# Returns: 0 if healthy (based on FAILURE_CONDITION), 1 if failed.
check_connectivity() {
    local failed_count=0
    local total_sources=${#MONITOR_SOURCES[@]}

    for source in "${MONITOR_SOURCES[@]}"; do
        if ping -c 1 -W 2 "$source" &> /dev/null; then
            log_message "SUCCESS: Ping to $source successful."
        else
            log_message "FAILURE: Ping to $source failed."
            ((failed_count++))
        fi
    done

    if [ "$FAILURE_CONDITION" == "ALL" ]; then
        if [ "$failed_count" -eq "$total_sources" ]; then
            return 1 # All failed
        fi
    elif [ "$FAILURE_CONDITION" == "ANY" ]; then
        if [ "$failed_count" -gt 0 ]; then
            return 1 # At least one failed
        fi
    fi

    return 0 # Healthy
}

# --- Main Execution ---

log_message "--- Starting Network Monitor ---"

if check_connectivity; then
    log_message "STATUS: Network is operationally healthy."
else
    log_message "STATUS: Network check FAILED (Condition: $FAILURE_CONDITION)."
    
    if [ "$ACTION_ON_FAILURE" == "restart" ]; then
        log_message "ACTION: Triggering network restart ($RESTART_CMD)..."
        # Execute the restart command
        eval "$RESTART_CMD"
        if [ $? -eq 0 ]; then
            log_message "ACTION_RESULT: Network restart command executed successfully."
        else
            log_message "ACTION_RESULT: Error executing network restart command."
        fi
    else
        log_message "ACTION: No action taken (ACTION_ON_FAILURE is set to '$ACTION_ON_FAILURE')."
    fi
fi

log_message "--- Finished ---"
exit 0
