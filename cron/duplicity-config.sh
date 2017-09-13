#!/bin/bash

# This file should be moved to $HOME/.duplicity-config.sh
# and then customized.

# These are the same on all hosts:
export SWIFT_AUTHURL="https://auth.cloud.ovh.net/v2.0/"
export SWIFT_AUTHVERSION="2"

# These need to be found from the OVH Cloud control panel at
# https://www.ovh.com/manager/cloud/index.html#/iaas/pci/project/b2c785157afa49e3871c343474806f38/openstack/users
# You could arrange for a different user/pass for each of the servers.
export SWIFT_USERNAME="xxxxxxx"
export SWIFT_PASSWORD="yyyyyyy"

# This comes from the "Horizon control panel", see:
# https://horizon.cloud.ovh.net/project/
export SWIFT_TENANTNAME="zzzzz"

# This one depends on the datacenter where you put the container for this
# host. See:
# https://www.ovh.com/manager/cloud/index.html#/iaas/pci/project/b2c785157afa49e3871c343474806f38/storage
export SWIFT_REGIONNAME="qqq"

# This is the symmetric encryption key used for the backups. It needs
# to be set every time duplicity is run, including for reading/auditing
# backups. (It can be any giant string. This example is from ps -ef | md5sum.)
#
# If you change it or lose it, you will LOSE ACCESS to all existing
# backups.
#
export PASSPHRASE=cd21ffcae529b3538cbe3ea1246f0be9
