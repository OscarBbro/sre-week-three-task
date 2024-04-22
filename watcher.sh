#!/bin/bash

# Configuration
NAMESPACE="sre"
DEPLOYMENT="swype-app"
MAX_RESTARTS=4
LOGFILE="/var/log/deployment_scaler.log"

# Function to log messages with timestamps
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Main loop
while true; do
    # Get the number of restarts of the pod
    RESTARTS=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath="{.items[0].status.containerStatuses[0].restartCount}" 2>&1)
    if [[ $? -ne 0 ]]; then
        log_message "Failed to get restart count for $DEPLOYMENT: $RESTARTS"
        sleep 60
        continue
    fi

    log_message "Current number of restarts: $RESTARTS"

    # Check if the number of restarts exceeds the maximum allowed
    if (( RESTARTS > MAX_RESTARTS )); then
        log_message "Maximum number of restarts exceeded. Scaling down the deployment..."
        kubectl scale --replicas=0 deployment/$DEPLOYMENT -n $NAMESPACE
        if [[ $? -eq 0 ]]; then
            log_message "Deployment $DEPLOYMENT successfully scaled down."
        else
            log_message "Failed to scale down deployment $DEPLOYMENT."
        fi
        break
    fi

    # Sleep before the next check
    sleep 60
done