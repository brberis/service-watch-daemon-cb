#!/bin/bash

### Check status, start, or restart services defined in an environment variable ###

if [ -z "$SERVICES_LIST" ]; then
    echo "No services specified. Set SERVICES_LIST environment variable."
    exit 1
fi

IFS=',' read -ra SERVICES <<< "$SERVICES_LIST"

check_service_status() {
    local service_name=$1

    # Check if the service is active
    isActive=$(systemctl is-active "$service_name")
    if [ "$isActive" = "active" ]; then
        # Service is running, now check if it has failed
        service_status=$(systemctl status "$service_name")
        if echo "$service_status" | grep -q "...fail!"; then
            return 1 # Service is running but failed
        else
            return 0 # Service is running and OK
        fi
    elif [ "$isActive" = "inactive" ] || [ "$isActive" = "failed" ]; then
        return 2 # Service is stopped or failed
    fi
}

max_attempts=1 

# Loop through each service in the list
for service_name in "${SERVICES[@]}"; do
    attempt_count=0

    while [ $attempt_count -lt $max_attempts ]; do
        check_service_status "$service_name"
        status=$?

        case $status in
            0)
                echo "$service_name service - O.K."
                ;;
            1)
                echo "$service_name Failed. Attempting to restart..."
                sudo systemctl restart "$service_name"
                ;;
            2)
                echo "$service_name is stopped. Attempting to start..."
                sudo systemctl start "$service_name"
                ;;
        esac

        ((attempt_count++))
        echo "Attempt $attempt_count of $max_attempts for $service_name."

        if [ $attempt_count -lt $max_attempts ]; then
            sleep 1
        else
            echo "Service $service_name status: failed to start after $max_attempts attempts."
            break
        fi
    done

    echo "Processing next service..."
done

echo "All services processed."
