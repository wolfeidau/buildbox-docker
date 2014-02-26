#!/bin/bash
set -e
set -x

rm -rf ssh
mkdir -p ssh
touch ssh/known_hosts
ssh-keyscan -H github.com >> ssh/known_hosts
ssh-keyscan -H bitbucket.com >> ssh/known_hosts
chmod 644 ssh/known_hosts
