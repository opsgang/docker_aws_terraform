#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:

img=opsgang/$IMG:candidate
_c=test_tf

docker rm -f $_c || true
test_name="default-with-preinstalled-plugins"
echo "INFO $0: test $test_name"
echo "INFO $0: ... should download versions as necessary."
var="export TV_VAR_ts=$test_name"
cmd="$var ; terraform init && terraform plan && terraform apply -auto-approve"
docker run -t --rm --name $_c -w /_test/default $img /bin/bash -c "$cmd"
