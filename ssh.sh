#!/bin/bash
set -e
set -x

rm -rf ssh
mkdir -p ssh
touch ssh/known_hosts
ssh-keyscan -p 22 -H github.com 2> /dev/null >> ssh/known_hosts
ssh-keyscan -p 22 -H bitbucket.com 2> /dev/null >> ssh/known_hosts
chmod 644 ssh/known_hosts
