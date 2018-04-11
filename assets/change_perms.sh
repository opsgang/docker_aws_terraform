#!/bin/bash
#
# When running aws_terraform as a different user under docker (e.g --user)
# we need to be able to create and delete files under the bin dir for terraform
# and the cache dir.
#
# This script (to be run via sudo) will change perms of the critical dirs.
# based on current user and group id
#

uid=$1
gid=$2

[[ $uid -eq 0 ]] && exit 0

BIN_DIR="${TERRAFORM_BIN}"
TF_PLUGINS_CACHE_DIR="${TF_PLUGINS_CACHE_DIR:-$PREINSTALLED_PLUGINS}"

if [[ "$TF_PLUGINS_CACHE_DIR" =~ /sbin ]] || [[ "$BIN_DIR" =~ /sbin ]]; then
    echo "ERROR $0: really? sbin? Not happening"
    exit 1
fi

echo "INFO $0: changing perms of bin dir $BIN_DIR and cache dir for uid:gid $uid:$gid."
if [[ ! -d $BIN_DIR ]] || [[ ! -w $BIN_DIR ]]; then
    echo "ERROR $0: $BIN_DIR is not a writable dir"
    exit 1
fi

chown -R $uid:$gid $BIN_DIR $TF_PLUGINS_CACHE_DIR
