[1]: https://www.terraform.io/ "Hashicorp terraform"
[2]: http://docs.aws.amazon.com/cli/latest/reference "use aws apis from cmd line"
[3]: https://github.com/fugue/credstash "credstash - store and retrieve secrets in aws"
[4]: https://github.com/opsgang/alpine_build_scripts/blob/master/install_essentials.sh "common GNU tools useful for automation"
[5]: https://github.com/opsgang/docker_aws_env "opsgang's aws_env docker image"

# docker\_aws\_terraform

_... alpine container with common tools and scripts to use Hashicorp's terraform on or for aws_

[![Run Status](https://api.shippable.com/projects/589913a86ee43c0f00b47cb6/badge?branch=master)](https://app.shippable.com/projects/589913a86ee43c0f00b47cb6)

> Use different versions of terraform. Use host volumes to cache plugins and
> terraform binaries for faster run-time.

> This image is always preloaded with the latest terraform at time it was built.

---

* [features](#features)

* [docker tags](#docker-tags)

* [building locally](#building)

* [running](#running)

    * [caching](#caching)

    * [changing terraform version](#changing-terraform-version)

    * [misc. examples](#other-example-uses)

---

## features

* [hashicorp's terraform][1]

* tools from [opsgang/aws\_env][5] including, [aws cli][2], [credstash][3] [and more][4]

## docker tags

**tags on master are built at shippable.com and available from dockerhub**

* terraform-*terraform_version* e.g. terraform-0.10.4
    - pull with specific terraform version preinstalled.

* terraform-*terraform_minor_version* e.g. terraform-0.10
    - will pull you the latest 0.10.x that we've built.

* _github tag_ - reference versions for opsgang peeps.

* _build timestamp_ - distinct for each image we've successfully pushed.
    - Of no obvious use to anyone else.

## building

**Don't forget to run the tests!**

```bash
git clone https://github.com/opsgang/docker_aws_terraform.git
cd docker_aws_terraform
./build.sh # adds custom labels to image
mkdir _t ; TMPD=$PWD/_t ./test.sh
```

## installing

```bash
docker pull opsgang/aws_terraform:stable # or use the tag you prefer
```

## running

### caching

Obviously as this is a container, the terraform version or the plugins
you download won't be there once the container is killed.

>
> So you don't have to keep downloading the same assets on
> every run, you can mount a host dir or docker vol to store
> the terraform binaries and another to store the plugins.
>

Bear in mind, the downloaded assets are only suitable for linux amd64
so don't expect the cached artefacts to work locally on your beloved
macbook as well as in the container.

> *REMEMBER:* the container's preinstalled binary is
> not available if you mount your terraform bin dir.

```bash
# CACHING TERRAFORM BINARIES:
# mount to /tf_bin
#
docker run -i --rm \
    -v /my/tf/bin:/tf_bin \
    [ ... other opts ...]
    opsgang/aws_terraform:stable <some cmds to run>

# CACHING PLUGINS: (if terraform version >=0.10.7)
# mount to /tf_plugin_cache_dir
#
docker run -i --rm \
    -v /my/cache/dir:/tf_plugin_cache_dir \
    [ ... other opts ...]
    opsgang/aws_terraform:stable <some cmds to run>
```

### changing terraform version

```bash
# To use a version of terraform not preinstalled:
# Set env var TERRAFORM_VERSION=<desired semantic version>
#
docker run --rm -i \
    -e TERRAFORM_VERSION=0.11.4 \
    [ ... other opts ... ]
    opsgang/aws_terraform:stable <some cmds to run>

```

### other example uses ...

```bash
# To run /path/to/script.sh which calls terraform, aws cli, curl, jq blah ...
docker run --rm -i -v /path/to/script.sh:/script.sh:ro opsgang/aws_terraform:stable /script.sh
```

```bash
# To make my aws creds available and run /some/python/script.py
export AWS_ACCESS_KEY_ID="i'll-never-tell" # replace glibness with your access key
export AWS_SECRET_ACCESS_KEY="that's-for-me-to-know" # amend as necessary

docker run --rm -i                      \ # ... run interactive to see stdout / stderr
    -v /some/python/script.py:/my.py:ro \ # ... assume the file is executable
    --env AWS_ACCESS_KEY_ID             \ # ... will read it from your env
    --env AWS_SECRET_ACCESS_KEY         \ # ... will read it from your env
    --env AWS_DEFAULT_REGION=eu-west-2  \ # ... adjust geography to taste
    opsgang/aws_terraform:stable /my.py      # script can access these env vars
```

```bash
# let me treat the container like a dev workspace and try stuff out.
# Oh look! vim is preinstalled. How cool! And gratuitous.
docker run -it --name my_workspace opsgang/aws_terraform:stable /bin/bash
```
