#!/bin/bash
set -e
set -x

docker build --tag "buildboxhq/base" .
