# rkt-stacks

[![Build Status](https://travis-ci.org/taqtiqa/rkt-stacks.svg?branch=master)](https://travis-ci.org/taqtiqa/rkt-stacks)

Opinionated Rkt stacks of ready-to-run Jupyter applications built on Travis-CI.

## Quick Start
For any of the Rkt image names, `IMG`:

1. `base-notebook`
1. `minimal-notebook`
1. `scipy-notebook`
1. `r-notebook`
1. `tensorflow-notebook`
1. `datascience-notebook`
1. `pyspark-notebook`
1. `all-spark-notebook`

````bash
IMG=all-spark-notebook
IMG_VER=8.4.4+0

sudo rkt trust --prefix=taqtiqa.io/$IMG

rkt fetch taqtiqa.io/$IMG:$IMG_VER

sudo rkt run --dns 8.8.8.8 --net=host \
--volume notebooks,kind=host,source=$(pwd) \
taqtiqa.io/${IMG}:${IMG_VER} \
--mount volume=notebooks,target=/notebooks \
--port=8888-tcp:8888 \
--user=1000 --group=1000 \
--set-env=GRANT_SUDO=yes \
--exec /bin/bash -- -c 'start.sh jupyter lab'
````

## Context
The Rkt build of the Jupyter stacks aims:

1. To be a 1:1 mapping of the upstream Jupyter/docker-stacks.
1. Support the Rkt style of secure registry

## Run rkt Container: Local file store
If the rkt conatiner is built on a desktop - rather than in the Travis-CI
build environment the image name will be `./image-name-0.0.0-0-linux-amd64.aci`
````bash
sudo rkt run --insecure-options=image --interactive ./image-name-0.0.0-0-linux-amd64.aci --exec bash
````
or 
````bash
sudo rkt run --net=host --insecure-options=image --interactive ./image-name-0.0.0-0-linux-amd64.aci --exec bash
````
or
````bash
sudo rkt run --dns 8.8.8.8 --net=host --insecure-options=image --interactive ./image-name-0.0.0-0-linux-amd64.aci --exec bash
````
