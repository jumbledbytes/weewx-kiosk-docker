# Introduction

The weewx-kiosk-docker project provides a set of configurations and a setup to host a weewx report on a Raspberry Pi that is connected to a 7 inch [touchscreen](https://www.raspberrypi.org/products/raspberry-pi-touch-display/). The Raspberry Pi is configured to start up in a Kiosk mode and load heavily customized Weewx report that is optimized for display on the 7 inch touchscreen display.

This project is built based on the excellent [Belchertown](https://github.com/poblabs/weewx-belchertown) Weewx skin.

This project contains a customized docker image the has Weewx installed and setup to generate reports from Weewx. The Weewx docker image is not configured to collect data, a separate Weewx instance is expected to perform those functions. The weewx instance is setup to only generate reports by connecting directly to the database that stores Weewx data.

# Prerequesites

## Hardware

You will need the following (or equivalents) to build the weather station kiosk as designed.

- A [Raspberry Pi](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/). A Raspberry Pi 4 was used for this project
- A 7 inch touchscreen for the Raspberry Pi. This project is optimized for the [official](https://www.raspberrypi.org/products/raspberry-pi-touch-display/) Raspberry Pi touchscreen with a resolution of 800x480.
- [Optional] A case for the the Raspberry Pi and display. There are many options, but I used the [SmartPi Touch 2](https://smarticase.com/products/smartipi-touch-2) from Smarticase.
- A system with [Docker](https://www.docker.com) installed.

## Software

In order to build and deploy the kiosk you will need the following:

- A running [Weewx](https://www.weewx.com) installation that saves data to a MySQL database.
- [Docker](https://www.docker.com) installed.
- [Optional] A MQTT server setup to provide live data updates to the kiosk display.

# Setup and Installation

## Hardware

- [Install](https://www.raspberrypi.org/software/) the Raspberry Pi OS on the Pi.
- Follow the [setup instructions](https://smarticase.com/pages/smartipi-touch-2-setup-1) from SmartiCase to setup the Raspberry Pi with the SmartTouch 2 Display.

## Software

### Setup the configuration

All of the parameterized configuration values that are installation specific are stored in a `.env.local` file. To create this file copy the `.env.local.dist` file to `.env.local` and modify the values as appropriate for your configuration.

Below is an example of what your `.env.local` might look like:

```
WEEWX_STATION_LOCATION="My Weather Station"
WEEWX_STATION_LATITUDE=30.1234
WEEWX_STATION_LONGITUDE=-125.987
WEEWX_STATION_ALTITUDE="550, foot"
WEEWX_STATION_URL=https://weatherstation.url.com
WEEWX_STATION_KIOSK_URL=https://weatherstation.url.com/kiosk

WEEWX_MYSQL_HOST=<mysql_host>
WEEWX_MYSQL_PORT=<mysql_port
WEEWX_MYSQL_USER=<mysql_user>
WEEWX_MYSQL_PASSWORD=<mysql_password

WEEWX_MQTT_ENABLED=1
WEEWX_MQTT_HOST="mqttserver.weatherstation.url.com"
WEEWX_MQTT_PORT=<mqtt_port>
WEEWX_MQTT_SSL=1
WEEWX_MQTT_TOPIC="weather/loop"
```

### Setup the Raspberry Pi

A small amoutn of manual configuration is required to setup the Raspberry Pi in Kiosk mode.

- Copy the `.env.local` file you setup above to `/home/pi/.weewx_kiosk` on the Raspberry Pi.
- Copy the `scripts/kiosk.sh` file to `/home/pi/kiosk.sh` in the Raspberry Pi.
- Copy the `conf/kiosk.desktop` file to `/home/pi/.config/autostart` on the Raspberry Pi.

### [Optional] Setup MQTT Broker

#### Installing the Mosquitto Server

If the `WEEWX_MQTT_ENABLED` value is 1 then you will need to have an MQTT broker available at the host and port you provided.

The following instructions are for configuring the MQTT broker on a Synology NAS.

Before setting up the MQTT broker you will need to configure your NAS with SSL certificates from Lets Encrypt if you intend to server you reports over an https connection.

You will need sure you have installed the Mosquitto community package on the Synology before proceeding. To install the Mosquitto package you first need to add the community packages to the package list:

- In Package Center -> General Set trust level to “Synolocy Inc. or any publisher”
- In Package Center -> Package Sources:
  - Click Add and enter `synocommunity` for name as http://packages.synocommunity.com for location
- In Package Center search for Mosquitto and install it.

#### Configuring the Mosquitto Server

The reports use websockets to communicate with the MQTT broker. Websockets are not enabled by default in Mosquitto.

To enable websockets you need to edit the mosquitto configuration files on the Synology. Open `/volume1/@appstore/mosquitto/var/mosquitto.conf`(Note your volume number may be different depending on where you installed Mosquitto) and in the file make sure the following is added (and/or uncommented):

```
# =================================================================
# Extra listeners
# =================================================================

# Listen on a port/ip address combination. By using this variable
# multiple times, mosquitto can listen on more than one port. If
# this variable is used and neither bind_address nor port given,
# then the default listener will not be started.
# The port number to listen on must be given. Optionally, an ip
# address or host name may be supplied as a second argument. In
# this case, mosquitto will attempt to bind the listener to that
# address and so restrict access to the associated network and
# interface. By default, mosquitto will listen on all interfaces.
# Note that for a websockets listener it is not possible to bind to a host
# name.
# listener port-number [ip address/host name]
#listener
listener 9001
```

and

```
# Choose the protocol to use when listening.
# This can be either mqtt or websockets.
# Certificate based TLS may be used with websockets, except that only the
# cafile, certfile, keyfile and ciphers options are supported.
#protocol mqtt
protocol websockets
```

**Note** The port 9001 must match the destination port used when setting up a reverse proxy below.

The setup does not cover configuring the Mosquitto server authentication and access control refer to the Mosquitto documentation for your version to instructions on how to configure authentication and access controls if you need them.

Once the changes are saved restart the Mosquitto server.

#### Configuring SSL for HTTPS

Once Mosquitto is installed you will need to set it up be be accessed via a secure SSL connection. If you don't do this and atempt to enable live updates in the reports from an https connection the websockets to the MQTT server will be blocked.

To set up Mosquitto to use SSL we are going to piggy back on Lets Encrypt Certificates. If you are not using https to server your reports (not recommended) then you can set `WEEWX_MQTT_SSL` to 0.

Instead of configuring Mosquitto to use certificates directly we are going to setup a reverse proxy on the Synology. To set up the reverse proxy go to the Synology Control Panel -> Application Portal -> Reverse Proxy and click `Create`. In the form give your reverse proxy a description, set Source Protocol to `HTTPS`, set the hostname value to match the value you saved in `WEEWX_MQTT_HOST` (i.e.`mqttserver.weatherstation.url.com`). Set the Port to match the value you saved for `WEEWX_MQTT_PORT`. In the destination section set Protocol to `HTTP`, Hostname to `localhost`, and port to 9001.

### Configure your Weewx server to use MQTT

Follow the instructions here to edit your weewx configuration to enable publishing to the Mosquitto broker you just setup

https://github.com/weewx/weewx/wiki/mqtt

### Build the Docker image

To build the docker image that will generate the reports run:

```
./scripts/build.sh
```

### Testing the Docker image

To run the docker image you just built run:

```
./scripts/launch.sh
```

If the Docker image built and started successfully it will generate a set of reports in the `reports` directory.

### Upgrading

If you want to update to the latest version of the kiosk reports run:

```
./scripts/update.sh
```

After updating you will need to rebuild the docker image and re-deploy the image to whereever the docker container for the image is running.
