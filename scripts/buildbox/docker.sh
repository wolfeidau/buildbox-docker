#!/bin/bash
set -e
set -x

sudo docker build --tag "buildbox/base" .
sudo docker push buildbox/base
