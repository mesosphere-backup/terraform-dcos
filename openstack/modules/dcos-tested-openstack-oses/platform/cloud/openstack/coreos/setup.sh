#!/bin/sh

sudo systemctl disable locksmithd
sudo systemctl stop locksmithd
sudo systemctl restart docker # Restarting docker to ensure its ready. Seems like its not during first usage.

# Restart timesync service to ensure any configuration
# changes (i.e. ntp server change) gets picked up. The
# impact is the dcos-checks-poststart unit
sudo systemctl restart systemd-timesyncd
