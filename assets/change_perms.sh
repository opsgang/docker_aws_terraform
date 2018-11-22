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

tfbin="${TERRAFORM_BIN}"
tfcd="${TF_PLUGIN_CACHE_DIR:-$PLUGIN_CACHE}"

rc=0
for dir in $tfbin $tfcd ; do
    if [[ ! -d $dir ]] || [[ ! -w $dir ]]; then
        echo >&2 "ERROR $0: $dir is not a writable dir"
        rc=1
    fi

    if [[ "$dir" =~ /sbin ]]; then
        echo >&2 "ERROR $0: really? sbin? Not happening"
        rc=1
    fi
done

[[ $rc -eq 0 ]] || exit 1

echo "INFO $0: changing perms of bin dir $tfbin and cache dir for uid:gid $uid:$gid."
chown -R $uid:$gid $tfbin $tfcd
