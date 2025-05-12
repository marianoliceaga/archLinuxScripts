#!/bin/bash

# Store known connections
declare -A known_connections

echo "Monitoring new remote connections..."

while true; do
    # Get the list of established remote connections
    current_connections=$(ss -tn state established | awk 'NR>1 {print $4, $5}')
    
    # Check each connection
    while IFS= read -r line; do
        if [[ -z "${known_connections[$line]}" ]]; then
            echo "New connection: $line"
            known_connections[$line]=1
        fi
    done <<< "$current_connections"
    
    sleep 2  # Adjust as needed

done
