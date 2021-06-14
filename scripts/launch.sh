#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

pushd $SCRIPT_DIR/..
source .env.local

mkdir -p reports
$SCRIPT_DIR/prepare_config.py
cp ./conf/skin.conf.local ./skins/Belchertown/skin.conf
cp ./conf/skin.conf.local ./skins/Belchertown-kiosk/skin.conf

docker run -d \
  -e TZ=$WEEWX_STATION_TIMEZONE\
  -v ${PWD}/skins:/etc/weewx/skins\
  -v ${PWD}/reports:/var/www/html/weewx\
  weewx/kiosk:latest
