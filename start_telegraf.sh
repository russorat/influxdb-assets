#!/bin/bash

export PATH=$GOPATH/src/github.com/influxdata/influxdb/bin/darwin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

INFLUX_TOKEN=$(influx auth list --json | jq -r '.[].token')
INFLUX_ORG=$(influx org list --json | jq -r '.[].name')
TELEGRAF_ID=$(influx telegrafs --json | jq -r '.[].id')
TELEGRAF_URL="http://localhost:9999/api/v2/telegrafs/$TELEGRAF_ID"
INFLUX_TOKEN=$INFLUX_TOKEN INFLUX_ORG=$INFLUX_ORG telegraf --config $TELEGRAF_URL