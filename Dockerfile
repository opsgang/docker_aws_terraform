# vim: et sr sw=4 ts=4 smartindent syntax=dockerfile:
FROM gliderlabs/alpine:3.6

LABEL \
      name="opsgang/aws_terraform" \
      vendor="sortuniq"            \
      description="common tools to run terraform in or for aws"

ENV TERRAFORM_VERSION=0.9.11

COPY alpine_build_scripts bootstrap.sh /alpine_build_scripts

RUN cp /alpine_build_scripts/bootstrap.sh /bootstrap.sh \
    && chmod a+x /bootstrap.sh \
    && sh /alpine_build_scripts/install_vim.sh \
    && sh /alpine_build_scripts/install_awscli.sh \
    && sh /alpine_build_scripts/install_credstash.sh \
    && sh /alpine_build_scripts/install_terraform.sh \
    && cp -a /alpine_build_scripts/install_terraform.sh \
        /usr/local/bin/terraform_version.sh \
    && sh /alpine_build_scripts/install_essentials.sh \
    && rm -rf /var/cache/apk/* /alpine_build_scripts 2>/dev/null

ENTRYPOINT ["/bootstrap.sh"]

# built with additional labels:
#
# version
# opsgang.awscli_version
# opsgang.credstash_version
# opsgang.jq_version
# opsgang.terraform_version
#
# opsgang.build_git_uri
# opsgang.build_git_sha
# opsgang.build_git_branch
# opsgang.build_git_tag
# opsgang.built_by
#
