#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:

rc=0
img=opsgang/${IMG:-aws_terraform}:candidate
_c=test_tf

t() {
    local test_name="$1"
    local cmd="$2"
}

test_name="default-with-preinstalled-plugins"
echo "INFO $0: test $test_name"
echo "INFO $0: ... should download versions as necessary."
var="export TF_VAR_ts=$test_name"
cmd="$var ; terraform init && terraform plan && terraform apply -auto-approve"
exp='Apply complete! Resources: 2 added, 0 changed, 0 destroyed.'
docker rm -f $_c 2>/dev/null || true
o=$(docker run --rm --name $_c -w /_test/default $img /bin/bash -c "$cmd")
if [[ $? -ne 0 ]] || [[ ! $(echo "$o" | grep "$exp") ]]; then
    echo "ERROR $0: failure"
    echo "$o"
    rc=1
else
    echo "INFO $0:   (passed)"
fi

test_name="try-preinstalled-copy-pre-0.10.7"
echo "INFO $0: test $test_name"
echo "INFO $0: ... should download versions as necessary."
var="export TF_VAR_ts=$test_name"
cmd="$var ; terraform init && terraform plan && terraform apply -auto-approve"
exp='Apply complete! Resources: 2 added, 0 changed, 0 destroyed.'
docker rm -f $_c 2>/dev/null || true
o=$(docker run --rm --name $_c -w /_test/default -e TERRAFORM_VERSION=0.10.6 $img /bin/bash -c "$cmd")
if [[ $? -ne 0 ]] || [[ ! $(echo "$o" | grep "$exp") ]]; then
    echo "ERROR $0: failure"
    echo "$o"
    rc=1
else
    echo "INFO $0:   (passed)"
fi

exit $rc
