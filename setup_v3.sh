#!/bin/bash

# assume default if nothing is passed in
CONFIG_PROFILE="default"
# check to see if a config profile name was passed in
if [ -z "$1" ]; then
    echo "No config profile supplied, assuming default..."
    echo "Checking if this instance has been set up..."
    IS_SETUP=$(influx config ls --json)
    if [ "$IS_SETUP" == "{}" ]; then
        echo "Setting up local instance..."
        influx setup -f -b telegraf -o influxdata -u admin -p something
    fi
else
    # A config profile was supplied, so let's switch to it
    ENV_EXISTS=$(influx config set -n $1 -a | grep Error)
    # If there was no error, let's assume it worked
    if [ -z "$ENV_EXISTS" ]; then
        echo "Successfully set config profile to $1..."
    else
        if [ -z "$INFLUX_TOKEN" ] || [ -z "$INFLUX_ORG" ] || [ -z "$INFLUX_URL" ]; then
            # There was an error so let's get out of here.
            echo "Config profile $1 not found and there is no way to set it up. Exiting."
            exit 1
        else
            influx config create -n $1 -u $INFLUX_URL -o $INFLUX_ORG -t $INFLUX_TOKEN -a
        fi
    fi
    CONFIG_PROFILE=$1
fi

echo "Checking for existing stacks..."
MONITORING_STACK_ID=$(influx stacks --stack-name monitoring --json | jq -r '.[].ID')
if [ -z "$MONITORING_STACK_ID" ]; then
    echo "No stack found. Initializing our stack..."
    MONITORING_STACK_ID=$(influx stacks init -n monitoring --json | jq -r '.ID')
fi

# Setting the base path
BASE_PATH="$(pwd)"

echo "Applying our stack..."
cat $BASE_PATH/monitoring/*.yml | \
influx apply --force true --stack-id $MONITORING_STACK_ID -q

echo "Everything was set up successfully!"