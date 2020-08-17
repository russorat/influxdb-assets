#!/bin/bash

echo "Setting up local instance..."
influx setup -f -b telegraf -o influxdata -u admin -p something

echo "Initializing our stack..."
MONITORING_STACK_ID=$(influx stacks init -n monitoring --json | jq -r '.ID')

# Setting the base path
BASE_PATH="$(pwd)"

echo "Applying our stack..."
cat $BASE_PATH/monitoring/*.yml | \
influx apply --force true --stack-id $MONITORING_STACK_ID -q

echo "Everything was set up successfully!"