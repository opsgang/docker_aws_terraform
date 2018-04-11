#!/bin/bash
terraform_version() {
    local rc=0 o=""
    o=$(terraform --version | grep -Po '(?<=Terraform v)[\d\.]+')
    if [[ $? -ne 0 ]] || [[ -z "$o" ]]; then
        echo "ERROR $0: could not determine terraform version from terraform --version" >&2
        rc=1
    else
        echo "$o"
    fi
    return $rc
}

# ... cp across plugins?
need_providers_copied () {
    # only interested if version more than or equal to 0.10.0
    local ge="0.10.0" lt="0.10.7" tv="$_TV"

    [[ $(echo -e "$tv\n$ge" | sort -V | head -n 1) == "$ge" ]] \
    && [[ $(echo -e "$tv\n$lt" | sort -V | head -n 1) == "$tv" ]] \
    && return 0

    return 1

}

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

echo "DEBUG: changing perms on dirs."
sudo -E /change_perms.sh $uid $gid || exit 1

# Add path to dir containing terraform binary to PATH
export PATH="$TERRAFORM_BIN:$PATH"

# install new version if specified
[[ -z "$TERRAFORM_VERSION" ]] || /usr/local/bin/terraform_version $TERRAFORM_VERSION  || exit 1

_TV=$(terraform_version) || exit 1

if need_providers_copied
then
    ref="https://www.terraform.io/docs/configuration/providers.html#provider-plugin-cache"
    echo "INFO $0: will copy default plugins to the working dir (tf version $_TV)."
    echo "INFO $0: ... it will only do this when terraform init is called."
    echo "INFO $0: If you upgrade to v.0.10.7+ terraform will do this for you."
    echo "INFO $0: - see docs at $ref"

    terraform() {
        if [[ "$1" == "init" ]]; then
            mkdir -p .terraform/plugins 2>/dev/null
            cp -a $PREINSTALLED_PLUGINS/* .terraform/plugins
        fi
        $(which terraform) "$@"
    }

    export -f terraform

else
    # ... set TF_PLUGIN_CACHE_DIR if not in .terraformrc or already passed by user
    # (Note that cache dir will be ignored unless terraform >= v0.10.7)
    if ! user_passed_cache_dir
    then
        export TF_PLUGIN_CACHE_DIR="$PREINSTALLED_PLUGINS"
        echo "DEBUG $0: setting TF_PLUGIN_CACHE_DIR in env to $TF_PLUGIN_CACHE_DIR."
    fi
fi

unset _TV need_providers_copied
echo "DEBUG: BOOTSTRAP FINISHED"
exec "$@"
