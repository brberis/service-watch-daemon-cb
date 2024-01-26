
#!/bin/bash

### Check status, start, or restart a given service ###

if [ $# -eq 0 ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

service_name=$1

check_service_status() {
    # Check if the service is active
    isActive=$(systemctl is-active $service_name)
    if [ "$isActive" = "active" ]; then
        # Service is running, now check if it has failed
        service_status=$(systemctl status $service_name)
        if echo "$service_status" | grep -q "...fail!"; then
            return 1 # Service is running but failed
        else
            return 0 # Service is running and OK
        fi
    elif [ "$isActive" = "inactive" ] || [ "$isActive" = "failed" ]; then
        return 2 # Service is stopped or failed
    fi
}

attempt_count=0
max_attempts=3

while [ $attempt_count -lt $max_attempts ]; do
    check_service_status
    status=$?

    case $status in
        0)
            echo "$service_name service - O.K."
            exit 0
            ;;
        1)
            echo "$service_name Failed. Attempting to restart..."
            sudo systemctl restart $service_name
            ;;
        2)
            echo "$service_name is stopped. Attempting to start..."
            sudo systemctl start $service_name
            ;;
    esac

    let attempt_count=attempt_count+1
    echo "Attempt $attempt_count of $max_attempts for $service_name."

    if [ $attempt_count -lt $max_attempts ]; then
        sleep 1
    else
        echo "Service $service_name status: failed to start after $max_attempts attempts."
        exit 1
    fi
done
