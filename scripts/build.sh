#!/usr/bin/env sh

VERSION=v0.0.1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

pushd $SCRIPT_DIR/..
python3 ./scripts/prepare_config.py

docker build\
  -t weewx/kiosk:latest\
  -t weewx/kiosk:$VERSION\
  .

rm conf/weewx.conf.local
