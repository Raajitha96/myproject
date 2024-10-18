#!/bin/bash

# IP address of the test server passed as an argument
TEST_SERVER_IP=$1

# Check if TEST_SERVER_IP is set
if [ -z "$TEST_SERVER_IP" ]; then
    echo "TEST_SERVER_IP is not set. Exiting."
    exit 1
fi

# Health check URL
HEALTH_CHECK_URL="http://$TEST_SERVER_IP:8080/sayHello"

# Number of attempts
MAX_ATTEMPTS=5
ATTEMPT=1
SLEEP_TIME=15  # Wait 15 seconds between attempts

# Perform health check up to MAX_ATTEMPTS
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Performing health check (Attempt $ATTEMPT/$MAX_ATTEMPTS) on $HEALTH_CHECK_URL"

    # Make a request to the health check endpoint and store the response
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL")

    # Check if the response is HTTP 200 (success)
    if [ "$RESPONSE" -eq 200 ]; then
        echo "SUCCESS"
        exit 0
    else
        echo "Health check failed: $RESPONSE. Retrying in $SLEEP_TIME seconds..."
    fi

    # Increment attempt counter
    ATTEMPT=$((ATTEMPT + 1))

    # Wait before the next attempt
    sleep $SLEEP_TIME
done

# If we reached here, all attempts failed
echo "Health check failed after $MAX_ATTEMPTS attempts. Exiting."
exit 1
