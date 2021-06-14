FROM python:3.8-slim-buster
COPY setup/ /tmp/setup/
ENV WEEWX_VERSION 4.5.1
ENV DEBIAN_FRONTEND noninteractive

# Install dependent packages
RUN apt-get update && \
  apt-get -y --no-install-recommends install wget ssh cron fonts-freefont-ttf rsyslog gnupg2 python3-dev default-libmysqlclient-dev gcc


# Install python dependencies
RUN apt-get -y --no-install-recommends install python3-pil
RUN apt-get -y --no-install-recommends install python3-mysqldb

RUN python3 -m pip install configparser
RUN python3 -m pip install cheetah3
RUN python3 -m pip install pyephem
RUN python3 -m pip install python-dotenv
RUN python3 -m pip install configobj
RUN python3 -m pip install serial
RUN python3 -m pip install usb
RUN python3 -m pip install mysqlclient
RUN python3 -m pip install Pillow

# Set up Weewx
RUN wget -qO - https://weewx.com/keys.html | apt-key add -
RUN wget -qO - https://weewx.com/apt/weewx-python3.list | tee /etc/apt/sources.list.d/weewx.list
RUN apt-get update
RUN apt-get -y --no-install-recommends install weewx

COPY weewx-belchertown-release-1.2.tar.gz /tmp/setup/weewx-belchertown.tar.gz

# The custom script validates weewx checksums
RUN mkdir -p /var/www/html/weewx
COPY ./conf/weewx.conf.local /etc/weewx/weewx.conf

# Install the Belchertown skin
RUN wee_extension --config=/etc/weewx/weewx.conf  --install /tmp/setup/weewx-belchertown.tar.gz

# Overwrite the default Belchertown skin with our customized versions
COPY ./skins/Belchertown /etc/weewx/skins/Belchertown
COPY ./skins/Belchertown-kiosk /etc/weewx/skins/Belchertown-kiosk
COPY ./conf/skin.conf.local /etc/weewx/skins/Belchertown/skin.conf
COPY ./conf/skin.conf.local /etc/weewx/skins/Belchertown-kiosk/skin.conf

# Ensure the image is up-to-date
RUN apt-get -y -u dist-upgrade

# Cleanup the installation
RUN apt-get clean && rm -rf /tmp/setup /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up the cron job to generate the reports on a schedule
COPY ./conf/crontab-weewx /etc/cron.d/crontab-weewx

# Set up the skin in the image, use a volume to override this
COPY ./skins /etc/weewx/skins

# Copy the customized config file to the container
COPY conf/weewx.conf.local /etc/weewx/weewx.conf
COPY conf/skin.conf.local /etc/weewx/skins/Belchertown-kiosk/skin.conf

# entry.sh generates the reports
# and then relies on a cronjob to periodically re-generate them
COPY ./scripts/entry.sh /
COPY ./scripts/generate_reports.sh /

RUN crontab /etc/cron.d/crontab-weewx
RUN chmod +x /entry.sh
RUN chmod +x /generate_reports.sh
CMD ["/entry.sh"]
