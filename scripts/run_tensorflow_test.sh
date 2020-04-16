#!/bin/bash -e
# Copyright 2019. IBM All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BASEDIR="$(dirname "$0")"
# build a PowerAI docker image (Docker file should already be there)
docker build . -t nvidia-powerai -f ${BASEDIR}/Dockerfile

# run a few tensorflow tests
nvidia-docker run --rm -v ${BASEDIR}/results:/tmp/results  nvidia-powerai bash -c "source /opt/DL/tensorflow/bin/tensorflow-activate; python /opt/DL/tensorflow/lib/python2.7/site-packages/tensorflow/examples/learn/multiple_gpu.py --test_with_fake_data > /tmp/results/results.txt 2>&1"

# get a timestamp
now=`date +"%m_%d_%Y-%H:%M:%S"`

# get the minio client
wget https://dl.min.io/client/mc/release/linux-ppc64le/mc
chmod +x mc

# move the results to an object storage bucket
./mc config host add icos $1 $2 $3
./mc cp ${BASEDIR}/results/results.txt icos/$4/results-$now.txt
rm mc
echo "SUCCESS: Tensorflow setup, sample test run, and output uploaded to ICOS bucket"