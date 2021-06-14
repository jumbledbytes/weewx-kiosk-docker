#!/bin/bash

service rsyslog start
/generate_reports.sh
/usr/sbin/cron && tail -f /var/log/cron.log
