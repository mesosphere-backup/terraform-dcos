#!/bin/sh

sudo systemctl disable locksmithd
sudo systemctl stop locksmithd
sudo systemctl restart docker # Restarting docker to ensure its ready. Seems like its not during first usage.
