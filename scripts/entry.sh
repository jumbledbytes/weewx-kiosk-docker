#!/bin/bash

service rsyslog start
/generate_reports.sh
touch /var/log/weewx.log
/usr/sbin/cron && tail -f /var/log/weewx.log
