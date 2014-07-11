#!/bin/bash
set -e
set -x

sudo docker build --tag "buildboxhq/base" .
