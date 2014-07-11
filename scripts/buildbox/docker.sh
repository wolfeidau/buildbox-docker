#!/bin/bash
set -e
set -x

sudo docker build --tag "buildboxhq/base" .
docker push buildbox/base
