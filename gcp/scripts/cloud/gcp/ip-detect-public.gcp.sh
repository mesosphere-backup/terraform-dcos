#!/bin/sh
# Example ip-detect script using an external authority
# Uses the GCP Metadata Service to get the node's internal
# ipv4 address
curl -fsSL http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'
