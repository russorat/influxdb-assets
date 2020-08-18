#!/bin/bash

killall influxd
# WARNING: THIS NEXT LINE WILL DELETE ALL YOUR DATA
rm -r ~/.influxdbv2
influxd > /dev/null 2>&1 &