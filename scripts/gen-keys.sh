#!/usr/bin/env bash
#
# Copyright (C) 2017 TAQTIQA LLC. <http://www.taqtiqa.com>
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

# NOTE:
# Travis is the CI environment setup supporting encrypted environment variables.
#
# Sign a file with a private GPG keyring and password.
#
# Usage: gen-keys.sh
#

echo "#########################################################"
echo "##"
echo "##  STARTING: $0"
echo "##"
echo "#########################################################"

set -exuo pipefail

if [[ $# -lt 1 ]] ; then
  echo "Usage: gen-keys.sh <tag>"
  echo "Example: gen-keys.sh 92fe05d1e7e5"
  exit 1
fi

KEY_TAG=$1

DEFAULT_DEPLOY_DIR=./deploy
# The -v option requires bash 4.2 or higher
if [[ ! -v SHIPPABLE ]]; then
   export CI="true"
fi
if [[ ! -v TRAVIS ]]; then
   export CI="true"
fi
DEFAULT_CI=${SHIPPABLE:-$CI}
DEFAULT_CI=${TRAVIS:-$DEFAULT_CI}

BUILD_DEPLOY_DIR=${DEFAULT_DEPLOY_DIR:-$DEFAULT_DEPLOY_DIR}
BUILD_CI=${DEFAULT_CI:-$DEFAULT_CI}

WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

GIT_URL=`git config --get remote.origin.url`
GIT_NAME=$(basename $GIT_URL .git)

PUBLIC_KEYRING="./${GIT_NAME}-publickeys.asc"

# Version tagged keyring name
PUBLIC_KEYRING_TAGGED="./${GIT_NAME}-publickeys-${KEY_TAG}.asc"

function deployend() {
    export EXIT=$?
    if [[ $EXIT != 0 ]]; then
      echo "Abnormal end."
    fi
    rm -f ./travis-ca.cert
    exit $EXIT
}

trap deployend EXIT

if [[ ! ${BUILD_CI} == "true" ]]; then
  echo "Not in a CI environment. Do not Deploy."
  exit 1
fi

if [[ $TRAVIS == "true" ]]; then
  # Some times we may need to ./../ here....
  pushd ${WORKING_DIR}
    mkdir -p "${BUILD_DEPLOY_DIR}"
    # Copy PUBLIC_KEYRING to DEFAULT_DEPLOY_DIR folder ready to be deployed
    if [ -f ${PUBLIC_KEYRING} ]; then
      # Make a versioned backup of public keyrings - in case of emergency
      rsync --checksum "${PUBLIC_KEYRING}" "${DEFAULT_DEPLOY_DIR}/${PUBLIC_KEYRING_TAGGED}"
      # Only replace the existing public keyring if it is changed.
      rsync --checksum "${PUBLIC_KEYRING}" "${DEFAULT_DEPLOY_DIR}/$(basename ${PUBLIC_KEYRING})"
      echo "A GPG public keyring is ready to deploy."
    else
      echo "#########################################################"
      echo "##"
      echo "##  WARNING: NOT RAISNG EXIT 1 UNTIL CAUSE AND EFFECT "
      echo "##           IS KNOWN. TO DO"
      echo "##"
      echo "#########################################################"

      echo "A GPG public keyring ${PUBLIC_KEYRING} NOT found!."
      # exit 1
    fi
  popd
fi