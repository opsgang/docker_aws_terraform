# vim: et sr sw=4 ts=4 smartindent syntax=dockerfile:
FROM opsgang/aws_env:stable

LABEL \
      name="opsgang/aws_terraform" \
      description="common tools to run terraform in or for aws"

ENV TERRAFORM_VERSION=0.11.7 \
    TERRAFORM_BIN=/tf_bin \
    PREINSTALLED_PLUGINS=/tf_plugins_cache_dir \
    PROVIDER_VERSIONS=/provider.versions

COPY assets /assets

RUN chmod a+x /assets/*.sh /assets/usr/local/bin/* \
    && cp -a /assets/. / \
    && chown -R 501:501 /_test/unpriv \
    && apk --no-cache --update add sudo unzip \
    && mkdir ${TERRAFORM_BIN} \
    && chmod a+w /etc/passwd /etc/group /etc/shadow \
    && echo 'ALL ALL=(ALL) NOPASSWD: SETENV: /change_perms.sh' > /etc/sudoers.d/change_perms \
    && bash /usr/local/bin/terraform_version \
    && bash /usr/local/bin/terraform_providers \
    && rm -rf /var/cache/apk/* /assets 2>/dev/null

ENTRYPOINT ["/bootstrap.sh"]

# built with additional labels:
#
# version
# opsgang.awscli_version
# opsgang.credstash_version
# opsgang.jq_version
# opsgang.terraform_version
# opsgang.terraform_provider_aws
# opsgang.terraform_provider_fastly
#
# opsgang.build_git_uri
# opsgang.build_git_sha
# opsgang.build_git_branch
# opsgang.build_git_tag
# opsgang.built_by
#
