#!/bin/bash
set -e

# setup the current repo as a package - super hax.
mkdir -p gopath/src/github.com/buildboxhq
ln -s `pwd` gopath/src/github.com/buildboxhq/buildbox-docker
export GOPATH="$GOPATH:`pwd`/gopath"

echo '--- install dependencies'
go get github.com/tools/godep
godep restore

echo '--- building'
./scripts/build.sh
