#!/bin/bash

echo "Generating weewx reports"
wee_reports /etc/weewx/weewx.conf > /var/log/weewx.log
