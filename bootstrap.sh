#!/bin/sh

# install new version if specified
[[ -z "$TERRAFORM_VERSION" ]] || /usr/local/bin/terraform_version $TERRAFORM_VERSION  || exit 1

exec "$@"
