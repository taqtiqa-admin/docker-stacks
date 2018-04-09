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

echo "#########################################################"
echo "##"
echo "##  STARTING: $0"
echo "##"
echo "#########################################################"

set -exuo pipefail

DEFAULT_ARCH=amd64
DEFAULT_TAG=8a1b90cbcba5
DEFAULT_TARGET_OS=linux
DEFAULT_DEPLOY_DIR=./deploy

BUILD_ARCH=${ARCH:-$DEFAULT_ARCH}
BUILD_TAG=${DEFAULT_TAG}
BUILD_TARGET_OS=${DEFAULT_TARGET_OS:-$DEFAULT_TARGET_OS}
BUILD_DEPLOY_DIR=${DEFAULT_DEPLOY_DIR:-$DEFAULT_DEPLOY_DIR}

mkdir -p "${BUILD_DEPLOY_DIR}"

# declare -a arr=('base-notebook' 'minimal-notebook' 'scipy-notebook'
# 'r-notebook' 'tensorflow-notebook' 
# 'datascience-notebook' 'pyspark-notebook' 'all-spark-notebook')
# 
# Example: 
# BUILD_JOBS would be defined in .travis.yml
declare -a arr=(${BUILD_JOBS})

## now loop through the above array
for NB_NAME in "${arr[@]}"
do
  eval NB=${NB_NAME}
  # Name pattern: ${NB}-${TRAVIS_TAG}-linux-${ARCH}.aci
  export NB_ACI="${NB}-${BUILD_TAG}-${BUILD_TARGET_OS}-${BUILD_ARCH}.aci"
  echo "#############################################################"
  echo "##  Start Processing ${NB} to ${NB_ACI}"
  echo "#############################################################"

  skopeo copy docker://jupyter/${NB}:${BUILD_TAG} oci:${NB}:${BUILD_TAG}
  tar cf ${NB}.oci -C ${NB} .
  rm -rf ${NB}

  docker2aci -image=${NB}:${BUILD_TAG} ${NB}.oci

  mkdir -p ./deploy/
  find ./ -name "*${NB}*\.aci" -exec mv {}  ./deploy/${NB_ACI} \;

  ./scripts/sign.sh ./deploy/${NB_ACI}

  cat ci/scripts/s3-deploy-rkt.sh | sudo -E bash 

  sudo -E find ./deploy -maxdepth 1 -type f -delete
done

./scripts/gen-keys.sh ${BUILD_TAG}
