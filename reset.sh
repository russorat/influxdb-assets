#!/bin/bash

killall influxd
rm -r ~/.influxdbv2
influxd > /dev/null 2>&1 &