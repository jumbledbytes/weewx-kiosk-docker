#!/usr/bin/env bash

mkdir -p reports
./scripts/prepare_config.py
cp ./conf/skin.conf.local ./skins/Belchertown/skin.conf
cp ./conf/skin.conf.local ./skins/Belchertown-kiosk/skin.conf

docker run -d \
  -v ${PWD}/skins:/etc/weewx/skins\
  -v ${PWD}/reports:/var/www/html/weewx\
  weewx/kiosk:latest
