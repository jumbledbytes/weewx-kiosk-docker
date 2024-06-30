#!/bin/bash

set -e
set -x

cd /tmp/setup
wget "https://weewx.com/downloads/released_versions/weewx-${WEEWX_VERSION}.tar.gz"

sha256sum -c < weewx_checksums
tar xvfz weewx-${WEEWX_VERSION}.tar.gz
cd weewx-${WEEWX_VERSION}
python3 setup.py build
python3 setup.py install --no-prompt
