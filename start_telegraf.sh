#!/bin/bash

export PATH=$GOPATH/src/github.com/influxdata/influxdb/bin/darwin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

CONFIG_PROFILE="default"
if [ -z "$1" ]; then
    echo "No env supplied, assuming local (default)"
else
    ENV_EXISTS=$(influx config set -n $1 -a | grep Error)
    if [ -z "$ENV_EXISTS" ]; then
        echo "Successfully set config profile to $1..."
    else
        echo "Config profile $1 not found. Exiting."
        exit 1
    fi
    CONFIG_PROFILE=$1
fi

INFLUX_URL=$(influx config ls --json | jq -r ".$CONFIG_PROFILE.url")
echo $INFLUX_URL

INFLUX_TOKEN=$(influx auth list --json | jq -r '.[].token')
INFLUX_ORG=$(influx org list --json | jq -r '.[].name')
TELEGRAF_ID=$(influx telegrafs --json | jq -r '.[].id')
TELEGRAF_URL=$INFLUX_URL"/api/v2/telegrafs/$TELEGRAF_ID"
INFLUX_URL=$INFLUX_URL INFLUX_TOKEN=$INFLUX_TOKEN INFLUX_ORG=$INFLUX_ORG telegraf --config $TELEGRAF_URL