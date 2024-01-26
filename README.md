# service-watch-daemon-cb#!/bin/bash

### Check status, start, or restart multiple services ###

IFS=',' read -ra SERVICES <<< "${SERVICES_LIST}"

if [ ${#SERVICES[@]} -eq 0 ]; then
    echo "No services specified. Set SERVICES_LIST environment variable."
    exit 1
fi

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

max_attempts=3

# Loop through each service
for service in "${SERVICES[@]}"; do
    attempt_count=0
    while [ $attempt_count -lt $max_attempts ]; do
        check_service_status "$service"
        status=$?

        case $status in
            0)
                echo "$service service - O.K."
                break
                ;;
            1)
                echo "$service Failed. Attempting to restart..."
                sudo systemctl restart "$service"
                ;;
            2)
                echo "$service is stopped. Attempting to start..."
                sudo systemctl start "$service"
                ;;
        esac

        ((attempt_count++))
        echo "Attempt $attempt_count of $max_attempts for $service."

        if [ $attempt_count -lt $max_attempts ]; then
            sleep 1
        else
            echo "Service $service status: failed to start after $max_attempts attempts."
            exit 1
        fi
    done
done
