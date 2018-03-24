#!/usr/bin/env bash
#
# Copyright (C) 2018 TAQTIQA LLC. <http://www.taqtiqa.com>
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License v3
#along with this program.
#If not, see <https://www.gnu.org/licenses/agpl-3.0.en.html>.
#

# # https://coreos.com/rkt/docs/latest/signing-and-verification-guide.html#distributing-images-via-meta-discovery


DEFAULT_ARCH=amd64
DEFAULT_TAG=0.0.0
DEFAULT_TARGET_OS=linux
DEFAULT_DEPLOY_DIR=./deploy

BUILD_ARCH=${ARCH:-$DEFAULT_ARCH}
BUILD_TAG=${TRAVIS_TAG:-$DEFAULT_TAG}
BUILD_TARGET_OS=${DEFAULT_TARGET_OS:-$DEFAULT_TARGET_OS}
BUILD_DEPLOY_DIR=${DEFAULT_DEPLOY_DIR:-$DEFAULT_DEPLOY_DIR}

mkdir -p "${BUILD_DEPLOY_DIR}"

declare -a arr=("base-notebook"
"minimal-notebook"
"scipy-notebook"
"r-notebook"
"tensorflow-notebook"
"datascience-notebook"
"pyspark-notebook"
"all-spark-notebook")

## now loop through the above array
for NB in "${arr[@]}"
do
  # Name pattern: ${NB}-${TRAVIS_TAG}-linux-${ARCH}.aci
  export NB_ACI="${NB}-${BUILD_TAG}-${BUILD_TARGET_OS}-${BUILD_ARCH}.aci"
  echo "#############################################################"
  echo "##  Start Processing ${NB} to ${NB_ACI}"
  echo "#############################################################"
  # or do whatever with individual element of the array
  stdbuf -oL rkt fetch --insecure-options=image docker://jupyter/${NB} --pull-policy=update | {
    while IFS= read -r line
    do
      export RKT_UUID="$line"
    done
    # The `rkt image export ...` won't work without the braces.
    echo "The RKT_UUID is: $RKT_UUID"
    rkt image export ${RKT_UUID} ./deploy/${NB_ACI} --overwrite
    ./scripts/sign.sh ./deploy/${NB_ACI}
    ./ci/scripts/s3-deploy-rkt.sh
    rm -rf ./deploy/*
  }
done
./scripts/gen-keys.sh ${BUILD_TAG}
