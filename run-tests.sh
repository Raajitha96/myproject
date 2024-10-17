#!/bin/bash

TEST_SERVER_IP=$1

# Check if TEST_SERVER_IP is set
if [ -z "$TEST_SERVER_IP" ]; then
    echo "TEST_SERVER_IP is not set. Exiting."
    exit 1
fi

# Health check URL
HEALTH_CHECK_URL="http://$TEST_SERVER_IP:8080/healthcheck"

# Perform health check
echo "Performing health check on $HEALTH_CHECK_URL"

# Make a request to the health check endpoint and store the response
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL")

# Check the response code
if [ "$RESPONSE" -eq 200 ]; then
    echo "Health check passed: $RESPONSE"
    exit 0
else
    echo "Health check failed: $RESPONSE"
    exit 1
fi
