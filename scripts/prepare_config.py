#!/usr/bin/env python3

import os
from dotenv import dotenv_values
import subprocess


# Get the current git sha and use that as the version
gitSha = subprocess.check_output(["git", "describe", "--always"]).strip()
envOverrides = dict()
envOverrides["WEEWX_THEME_VERSION"] = gitSha.decode('utf-8')

config = {
    **dotenv_values(".env"),  # load shared development variables
    **dotenv_values(".env.local"),  # load sensitive variables
    **envOverrides,
    **os.environ,  # override loaded values with environment variables
}

updatedConfig = ""
# Replace all of the variables in the config file with values from the environment
with open('conf/weewx.conf', 'r') as configFile:

    # read file
    configText = configFile.read()

    # replace 'PHP' with 'PYTHON' in the file
    updatedConfig = configText
    for configKey in config:
        updatedConfig = updatedConfig.replace(
            '${' + configKey + '}', config.get(configKey))

if updatedConfig != "":
    with open('conf/weewx.conf.local', 'w') as configFile:
        # save output
        configFile.write(updatedConfig)

skinConfig = ""
# Replace all of the variables in the config file with values from the environment
with open('conf/skin.conf', 'r') as configFile:

    # read file
    configText = configFile.read()

    # replace 'PHP' with 'PYTHON' in the file
    skinConfig = configText
    for configKey in config:
        skinConfig = skinConfig.replace(
            '${' + configKey + '}', config.get(configKey))

if skinConfig != "":
    with open('conf/skin.conf.local', 'w') as configFile:
        # save output
        configFile.write(skinConfig)
