#!/bin/bash

ENV_FILE=.env
if test -f "$ENV_FILE"; then
    export $(grep -v '^#' .env | xargs)
fi

export PATH=$GOPATH/src/github.com/influxdata/influxdb/bin/darwin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

if [ -n "$BUCKETS_STACK_ID" ]; then
  echo "found stack ids" 
  #INFLUX_TOKEN=$INFLUX_TOKEN INFLUX_ORG=$INFLUX_ORG telegraf --config $TELEGRAF_URL
else
  echo "Can't find any Stack Ids, so let's set things up."
  influx setup -f -b telegraf -o influxdata -u russ -p something
  BUCKETS_STACK_ID=$(influx stacks init -n buckets --json | jq -r '.ID')
  TELEGRAFS_STACK_ID=$(influx stacks init -n telegrafs --json | jq -r '.ID')
  DASHBOARDS_STACK_ID=$(influx stacks init -n dashboards --json | jq -r '.ID')
  TASKS_STACK_ID=$(influx stacks init -n tasks --json | jq -r '.ID')
  
  # Save the stack ids to use later
  echo "export BUCKETS_STACK_ID=$BUCKETS_STACK_ID" >> .env
  echo "export TELEGRAFS_STACK_ID=$TELEGRAFS_STACK_ID" >> .env
  echo "export DASHBOARDS_STACK_ID=$DASHBOARDS_STACK_ID" >> .env
  echo "export TASKS_STACK_ID=$TASKS_STACK_ID" >> .env
fi

influx stacks update --stack-id $BUCKETS_STACK_ID -n buckets --template-url file://$(pwd)/buckets.yml
influx apply --force true --stack-id $BUCKETS_STACK_ID -q

TELEGRAF_FILES=""
for f in telegrafs/*.yml
do
  TELEGRAF_FILES+="-u \"file://$(pwd)/$f\" "
done
eval "influx stacks update --stack-id $TELEGRAFS_STACK_ID -n telegrafs $TELEGRAF_FILES"
influx apply --force true --stack-id $TELEGRAFS_STACK_ID -q

DASHBOARD_FILES=""
for f in dashboards/*.yml
do
  DASHBOARD_FILES+="-u \"file://$(pwd)/$f\" "
done
eval "influx stacks update --stack-id $DASHBOARDS_STACK_ID -n dashboards $DASHBOARD_FILES"
influx apply --force true --stack-id $DASHBOARDS_STACK_ID -q

TASK_FILES=""
for f in tasks/*.yml
do
  TASK_FILES+="-u \"file://$(pwd)/$f\" "
done
eval "influx stacks update --stack-id $TASKS_STACK_ID -n tasks $TASK_FILES"
influx apply --force true --stack-id $TASKS_STACK_ID -q


INFLUX_TOKEN=$(influx auth list --json | jq -r '.[].token')
INFLUX_ORG=$(influx org list --json | jq -r '.[].name')
TELEGRAF_ID=$(influx telegrafs --json | jq -r '.[].id')
TELEGRAF_URL="http://localhost:9999/api/v2/telegrafs/$TELEGRAF_ID"