#!/bin/bash
set -e
set -x

DIRECTORY=pkg
if [ -d "$DIRECTORY" ]; then
  rm -rf "$DIRECTORY"
fi
mkdir -p "$DIRECTORY"

GOOS="linux" GOARCH="amd64" go build -o $DIRECTORY/buildbox-docker
