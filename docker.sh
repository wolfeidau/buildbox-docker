#!/bin/bash
set -e
set -x

docker build --no-cache --rm true -t buildboxhq/base .
