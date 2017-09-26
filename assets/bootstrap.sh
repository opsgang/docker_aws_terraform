#!/bin/bash
need_providers() {
    # only interested if version more than or equal to 0.10.0
    local valid="0.10.0" tv=""
    tv=$(terraform --version | grep -Po '(?<=Terraform v)[\d\.]+')
    if [[ $? -ne 0 ]] || [[ -z "$tv" ]]; then
        echo "ERROR $0: could not determine terraform version from terraform --version" >&2
        exit 1 # deliberately short-circuit, as return val used for truth
    fi

    # list versions in ascending order and ensure our current version not first listed.
    [[ $(echo -e "$tv\n$valid" | sort -V | head -n 1) != "$tv" ]]

}

PROVIDERS_DIR=/tf_providers
# install new version if specified
[[ -z "$TERRAFORM_VERSION" ]] || /usr/local/bin/terraform_version $TERRAFORM_VERSION  || exit 1

# cp across providers to $TERRAFORM_WORKING_DIR
if needs_providers
then
    if [[ ! -z "$TERRAFORM_WORKING_DIR" ]] && [[ -w "$TERRAFORM_WORKING_DIR" ]]; then
        cp -a $PROVIDERS_DIR/.terraform $TERRAFORM_WORKING_DIR
    fi
fi
exec "$@"
