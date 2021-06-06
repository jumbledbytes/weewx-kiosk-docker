#!/usr/bin/env bash

docker run -d \
  -v ${PWD}/skins:/etc/weewx/skins\
  -v ${PWD}/reports:/var/www/html/weewx\
  weewx/kiosk:latest
