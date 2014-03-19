#!/bin/bash
set -e
set -x

docker build --no-cache --rm --tag "buildboxhq/base" .
