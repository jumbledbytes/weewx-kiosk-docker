#!/usr/bin/env sh

VERSION=v0.0.1

python3 scripts/prepare_config.py

docker build --progress=plain\
  -t weewx/kiosk:latest\
  -t weewx/kiosk:$VERSION\
  .

rm conf/weewx.conf.local