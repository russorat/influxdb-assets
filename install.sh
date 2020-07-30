#!/bin/bash

export PATH=$GOPATH/src/github.com/influxdata/influxdb/bin/darwin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

CONFIG_PROFILE="default"
if [ -z "$1" ]; then
    echo "No env supplied, assuming local (default)"
    echo "Checking if this instance has been set up..."
    IS_SETUP=$(influx config ls --json)
    if [ -z "$IS_SETUP" ]; then
        influx setup -f -b telegraf -o influxdata -u russ -p something
    fi
else
    ENV_EXISTS=$(influx config set -n $1 -a | grep Error)
    if [ -z "$ENV_EXISTS" ]; then
        echo "Successfully set config profile to $1..."
    else
        if [ -z "$INFLUX_TOKEN" ]; then
            echo "Config profile $1 not found and no way to create it. Exiting."
            exit 1
        else
            influx config create -n $1 -u $INFLUX_URL -o $INFLUX_ORG -t $INFLUX_TOKEN -a
        fi
    fi
    CONFIG_PROFILE=$1
fi

INFLUX_URL=$(influx config ls --json | jq -r ".$CONFIG_PROFILE.url")

echo "Checking for existing Stacks..."
BUCKETS_STACK_ID=$(influx stacks --stack-name buckets --json | jq -r '.[].ID')
if [ -z "$BUCKETS_STACK_ID" ]; then
    BUCKETS_STACK_ID=$(influx stacks init -n buckets --json | jq -r '.ID')
fi

TELEGRAFS_STACK_ID=$(influx stacks --stack-name telegrafs --json | jq -r '.[].ID')
if [ -z "$TELEGRAFS_STACK_ID" ]; then
    TELEGRAFS_STACK_ID=$(influx stacks init -n telegrafs --json | jq -r '.ID')
fi

DASHBOARDS_STACK_ID=$(influx stacks --stack-name dashboards --json | jq -r '.[].ID')
if [ -z "$DASHBOARDS_STACK_ID" ]; then
    DASHBOARDS_STACK_ID=$(influx stacks init -n dashboards --json | jq -r '.ID')
fi

TASKS_STACK_ID=$(influx stacks --stack-name tasks --json | jq -r '.[].ID')
if [ -z "$TASKS_STACK_ID" ]; then
    TASKS_STACK_ID=$(influx stacks init -n tasks --json | jq -r '.ID')
fi

BASE_PATH="file://$(pwd)"
if [[ $INFLUX_URL =~ "cloud2.influxdata.com" ]]; then
    BASE_PATH="https://github.com/russorat/influxdb-gitops/blob/master"
fi

influx stacks update --stack-id $BUCKETS_STACK_ID -n buckets --template-url $BASE_PATH/buckets.yml
influx apply --force true --stack-id $BUCKETS_STACK_ID -q

TELEGRAF_FILES=""
for f in telegrafs/*.yml
do
  TELEGRAF_FILES+="-u \"$BASE_PATH/$f\" "
done
eval "influx stacks update --stack-id $TELEGRAFS_STACK_ID -n telegrafs $TELEGRAF_FILES"
influx apply --force true --stack-id $TELEGRAFS_STACK_ID -q

DASHBOARD_FILES=""
for f in dashboards/*.yml
do
  DASHBOARD_FILES+="-u \"$BASE_PATH/$f\" "
done
eval "influx stacks update --stack-id $DASHBOARDS_STACK_ID -n dashboards $DASHBOARD_FILES"
influx apply --force true --stack-id $DASHBOARDS_STACK_ID -q

TASK_FILES=""
for f in tasks/*.yml
do
  TASK_FILES+="-u \"$BASE_PATH/$f\" "
done
eval "influx stacks update --stack-id $TASKS_STACK_ID -n tasks $TASK_FILES"
influx apply --force true --stack-id $TASKS_STACK_ID -q