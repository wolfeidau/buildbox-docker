#!/bin/bash
set -e
set -x

DIRECTORY=pkg
if [ -d "$DIRECTORY" ]; then
  rm -rf "$DIRECTORY"
fi
mkdir -p "$DIRECTORY"

function build {
  FILENAME=buildbox-docker-$1-$2
  GOOS=$1 GOARCH=$2 go build -o $DIRECTORY/$FILENAME
  gzip $DIRECTORY/$FILENAME
}

build "linux" "amd64"
build "darwin" "amd64"
