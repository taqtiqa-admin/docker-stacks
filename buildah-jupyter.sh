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

# IMPORTANT: Your .travis.yml must pipe this script to bash (not to sh)!
# In the Travis CI environment a #!/bin/bash shebang here won't help.


buildah build-using-dockerfile base-notebook/ --tag base-notebook
buildah push 9d8d582f1cf2 oci:base-notebook.oci:latest
docker2aci -debug ./base-notebook.oci

# This outputs the UUID (sha512-54132af0ead11ad8c361ff9)

# Reference:
# https://github.com/jupyter/docker-stacks

## declare an array variable 
#"base-notebook"
#"minimal-notebook" 

declare -a arr=("scipy-notebook"
"r-notebook"
"tensorflow-notebook"
"datascience-notebook"
"pyspark-notebook"
"all-spark-notebook")

## now loop through the above array
for i in "${arr[@]}"
do
  echo "#############################################################"
  echo "##  Start Processing $i"
  echo "#############################################################"
  # or do whatever with individual element of the array
  stdbuf -oL sudo rkt fetch --insecure-options=image docker://jupyter/${NB} --pull-policy=update | {
    while IFS= read -r line
    do
      echo "$line"
      export RKT_UUID="$line"
    done

    # This won't work without the braces.
    echo "The RKT_UUID is: $RKT_UUID"
    sudo rkt image export ${RKT_UUID} ./${NB}.aci --overwrite
  }
 
done


export NB=minimal-notebook
sudo rkt run --insecure-options=image docker://jupyter/${NB} --name=${NB} --uuid-file-save=./rkt-${NB}.uuid
sudo rkt image list
sudo rkt image export ${RKT_UUID} ./${NB}.aci
sudo rkt fetch --insecure-options=image ./${NB}.aci --name=${NB}

echo "Sign the Container Image..."
./scripts/sign.sh ${BUILD_ARTIFACT}
echo "Signed the Container Image..."

#--set-env-file rkt_env.sh \
#--interactive <UUID> \

sudo rkt run --volume notebooks,kind=host,source=$(pwd) \
./${NB}.aci \
--mount volume=notebooks,target=/home/jovyan/work \
--port=8888-tcp:8888 \
--insecure-options=image \
--user=1000 --group=1000 \
--set-env=GRANT_SUDO=yes \
--exec /bin/bash -- -c 'start.sh jupyter lab'

sudo rkt run --volume notebooks,kind=host,source=$(pwd) \
./${NB}.aci \
--mount volume=notebooks,target=/notebooks \
--port=8888-tcp:8888 \
--insecure-options=image \
--user=1000 --group=1000 \
--set-env=GRANT_SUDO=yes \
--exec /bin/bash -- -c 'start.sh jupyter lab'