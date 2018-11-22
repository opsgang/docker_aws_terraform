#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:

# Running locally:
# export TMPD to be absolute path to a dir that docker
# can mount.
# e.g.
#    mkdir -p _t ; TMPD=$PWD/_t ./test.sh
# We use the TMPD dir to test some of the "caching"
# functionality. To make sure we can run this locally from
# within another container as well as from your host machine,
# we run a separate docker container for the shared mounts.
#
# In shippable, we use pre_ci_boot options to do the same.
# and use a different mount arg for docker run.
#
vol_str_for_caches() {
    echo --volumes-from ${SHIPPABLE_CONTAINER_NAME:-$LOCAL_CACHE_CONTAINER}
}

rc=0

img=opsgang/${IMG:-aws_terraform}:candidate
_c=test_tf
cmd='sleep 3 ; terraform init -input=false ; terraform apply -input=false -auto-approve'

# ... used in tests for cache dirs if not running in shippable.
LOCAL_CACHE_CONTAINER=tf_cache_dirs
tmpd=${TMPD:-/var/tmp}
tfcd=$tmpd/tf_plugin_cache_dir
tfbin=$tmpd/tf_bin 

if [[ -z "$SHIPPABLE_CONTAINER_NAME" ]]; then
    echo "INFO $0: running local container to act as mounted vols"
    echo "INFO $0: we do this, because locally we might run the build"
    echo "INFO $0: within another container ..."

    docker rm -f $LOCAL_CACHE_CONTAINER 2>/dev/null
    docker run -d --name $LOCAL_CACHE_CONTAINER \
        -v $tfcd:/tf_plugin_cache_dir \
        -v $tfbin:/tf_bin \
        alpine:3.8 /bin/sh -c 'while true; do sleep 1000; done'
fi

(
    rc=0
    test_name="default-with-preinstalled"
    var="export TF_VAR_ts=$test_name"
    exp='Apply complete! Resources: 2 added, 0 changed, 0 destroyed.'

    echo "INFO $0: $test_name"

    docker rm -f $_c 2>/dev/null || true
    o=$(
        docker run --rm --name $_c \
            -w /_test/default \
            $img /bin/bash -c "$var ; $cmd"
    )
    if [[ $? -ne 0 ]] || [[ ! $(echo "$o" | grep "$exp") ]]; then
        echo "ERROR $0: $test_name failure"
        echo "$o"
        rc=1
    else
        echo "INFO $0: $test_name   (passed)"
    fi
    docker rm -f $_c 2>/dev/null || true
    rm -rf _test/.terraform _test/default/.terraform
) || rc=1

(
    rc=0
    test_name="try-different-terraform-version"
    var="export TF_VAR_ts=$test_name"
    exp='Apply complete! Resources: 2 added, 0 changed, 0 destroyed.'
    v=0.10.6
    exp_v='Terraform v0\.10\.6$'

    echo "INFO $0: $test_name"
    echo "INFO $0: $test_name ... user can specify terraform version to use"

    docker rm -f $_c 2>/dev/null || true
    o=$(
        docker run --rm --name $_c \
            -w /_test/default \
            -e TERRAFORM_VERSION=$v \
            $img /bin/bash -c "$var ; $cmd"
    )
    if [[ $? -ne 0 ]] || [[ ! $(echo "$o" | grep "$exp") ]] || [[ ! $(echo "$o" | grep -P "$exp_v") ]] ; then
        echo "ERROR $0: $test_name failure"
        echo "$o"
        rc=1
    else
        echo "INFO $0: $test_name   (passed)"
    fi
    docker rm -f $_c 2>/dev/null || true
    exit $rc
) || rc=1

(
    rc=0
    test_name="try-unprivileged-user"
    var="export TF_VAR_ts=$test_name"
    exp='Apply complete! Resources: 2 added, 0 changed, 0 destroyed.'

    echo "INFO $0: $test_name"
    echo "INFO $0: $test_name ... trying non-root users with docker run --user "

    for uid_gid in 501:501 0:0 501:501; do

    echo "INFO $0: $test_name ... trying $uid_gid"
        _c=$c_$(date '+%Y%m%d%H%M%S')
        docker rm -f $_c 2>/dev/null || true
        o=$(
            docker run --rm --name $_c \
                -w /_test/unpriv \
                --user $uid_gid \
                $img /bin/bash -c "$var ; $cmd"
        )
        if [[ $? -ne 0 ]] || [[ ! $(echo "$o" | grep "$exp") ]]; then
            echo "ERROR $0: $test_name failure"
            echo "$o"
            rc=1
        else
            echo "INFO $0: $test_name    (uid:gid[$uid_gid]: passed)"
        fi
        docker rm -f $_c 2>/dev/null || true
    done
    rm -rf _test/.terraform _test/default/.terraform

    exit $rc
) || rc=1

(
    rc=0
    test_name="test-mounted-tf-dirs"
    var="export TF_VAR_ts=$test_name"
    exp='.*/tf_bin/terraform-[\d\.]+ .*/tf_plugin_cache_dir/linux_amd64/terraform-provider-null_v'

    echo "INFO $0: $test_name"
    echo "INFO $0: $test_name ... trying with mounted cache and tf_bin dirs as root user (default)"

    docker rm -f $_c 2>/dev/null

    [[ -z "$SHIPPABLE_CONTAINER_NAME" ]] && rm -rf $tfbin/* $tfcd/*

    docker run -it --rm --name $_c \
        $(vol_str_for_caches) \
        -w /_test/default \
        $img /bin/bash -c "$var ; $cmd" >/dev/null || exit 1

    docker rm -f $_c 2>/dev/null

    if [[ -z "$SHIPPABLE_CONTAINER_NAME" ]]; then
        o="$(find $tfbin $tfcd -type f | sort)"
    else
        o="$(find /tf_bin /tf_plugin_cache_dir -type f | sort)"
    fi

    if ! echo $o | grep -P "$exp" >/dev/null
    then
        echo "ERROR $0: $test_name failed to find expected files."
        echo -e "... files in mounted vols:\n$o"
        rc=1
    else
        echo "INFO $0: $test_name   (passed)"
    fi

    exit $rc
) || rc=1

(
    rc=0
    test_name="test-mounted-tf-dirs-from-root-to-unpriv"
    var="export TF_VAR_ts=$test_name"
    exp='.*/tf_bin/terraform-[\d\.]+ .*/tf_plugin_cache_dir/linux_amd64/terraform-provider-null_v'

    echo "INFO $0: $test_name"
    echo "INFO $0: $test_name ... trying with mounted cache and tf_bin dirs as unpriv user with root-owned content"

    docker rm -f $_c 2>/dev/null

    [[ -z "$SHIPPABLE_CONTAINER_NAME" ]] && rm -rf $tfbin/* $tfcd/*

    docker run -it --rm --name $_c \
        $(vol_str_for_caches) \
        --user 501:501 \
        -w /_test/unpriv \
        $img /bin/bash -c "$var ; $cmd" >/dev/null || exit 1

    docker rm -f $_c 2>/dev/null

    if [[ -z "$SHIPPABLE_CONTAINER_NAME" ]]; then # if running locally
        o="$(find $tfbin $tfcd -type f | sort)"
    else
        o="$(find /tf_bin /tf_plugin_cache_dir -type f | sort)"
    fi

    if ! echo $o | grep -P "$exp" >/dev/null
    then
        echo "ERROR $0: $test_name failed to find expected files."
        echo -e "... files in mounted vols:\n$o"
        rc=1
    else
        echo "INFO $0: $test_name  (passed)"
    fi

    exit $rc
) || rc=1

docker rm -f tf_cache_dirs 2>/dev/null

exit $rc
