#!/bin/bash

service rsyslog start
/generate_reports.sh
crontab /etc/cron.d/crontab-weewx
/usr/sbin/cron -f
