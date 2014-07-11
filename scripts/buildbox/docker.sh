#!/bin/bash
set -e
set -x

sudo docker build --tag "buildbox/base" .
docker push buildbox/base
