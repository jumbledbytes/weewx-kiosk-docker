#!/bin/bash

echo "Generating weewx reports"
source /.env.local
export TZ=$WEEWX_STATION_TIMEZONE
wee_reports /etc/weewx/weewx.conf > /var/log/weewx.log
