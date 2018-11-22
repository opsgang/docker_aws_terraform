#!/bin/bash
# return 0 if user has specified either:
# * plugin_cache_dir in $HOME/.terraformrc
# * passed $TF_PLUGIN_CACHE_DIR to container
user_passed_cache_dir() {
    local f=$HOME/.terraformrc
    [[ ! -z "$TF_PLUGIN_CACHE_DIR" ]] && return 0
    [[ -r $f ]] && grep -P '^\s*plugin_cache_dir\s*=' $f >/dev/null && return 0

    return 1
}

# set up /usr/local/bin for this user
uid=$(id -u)
gid=$(id -g)

if ! getent group $gid >/dev/null 2>&1
then
    echo "INFO: creating group $gid for sudo"
    echo "$gid:x:$gid:$gid" >>/etc/group
fi

if ! getent passwd $uid >/dev/null 2>&1
then
    echo "INFO: creating user $uid for sudo"
    echo "$uid:x:$uid:$gid:$uid:/:/bin/ash" >>/etc/passwd
fi

sudo -E /change_perms.sh $uid $gid || exit 1

# Add path to dir containing terraform binary to PATH
export PATH="$TERRAFORM_BIN:$PATH"

# install new version if specified
[[ -z "$TERRAFORM_VERSION" ]] || /usr/local/bin/terraform_version $TERRAFORM_VERSION  || exit 1

# ... set TF_PLUGIN_CACHE_DIR if not in .terraformrc or already passed by user
# (Note that cache dir will be ignored unless terraform >= v0.10.7)
user_passed_cache_dir || export TF_PLUGIN_CACHE_DIR="$PLUGIN_CACHE"

exec "$@"
