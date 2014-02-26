#!/bin/bash
set -e
set -x

export DOCKER_HOST=tcp://0.0.0.0:4243
docker run -rm -i -t buildboxhq/base /bin/bash --login
