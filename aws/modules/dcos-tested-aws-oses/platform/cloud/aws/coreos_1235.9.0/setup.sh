#!/bin/sh

sudo systemctl disable locksmithd
sudo systemctl stop locksmithd
sudo systemctl mask locksmithd

sudo systemctl disable update-engine
sudo systemctl stop update-engine
sudo systemctl mask update-engine
sudo systemctl restart docker # Restarting docker to ensure its ready. Seems like its not during first usage.
