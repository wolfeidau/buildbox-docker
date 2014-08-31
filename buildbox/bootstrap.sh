#!/bin/bash

BUILDBOX_PROMPT="\033[90m$\033[0m"

function buildbox-exit-if-failed {
  if [ $1 -ne 0 ]
  then
    exit $1
  fi
}

function buildbox-run {
  echo -e "$BUILDBOX_PROMPT $1"
  eval $1
  buildbox-exit-if-failed $?
}

echo '--- booting vm environment'

buildbox-run "sudo mysqld_safe &"
buildbox-run "sudo /etc/init.d/postgresql start"
buildbox-run "sudo /etc/init.d/redis start"
buildbox-run "Xvfb :99 -ac > /dev/null 2>&1 & export DISPLAY=:99"

# This will return the location of this file. We assume that the buildbox-artifact
# tool is in the same folder. You can of course customize the locations
# and edit this file.
BUILDBOX_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Add the $BUILDBOX_DIR to the $PATH
export PATH="$BUILDBOX_DIR:$PATH"

# Create the build directory
BUILDBOX_BUILD_DIR="$BUILDBOX_CACHE_DIRECTORY/repos/$BUILDBOX_PROJECT_SLUG"

buildbox-run "mkdir -p $BUILDBOX_BUILD_DIR"
buildbox-run "cd $BUILDBOX_BUILD_DIR"

# Default empty branch names
if [ "$BUILDBOX_BRANCH" == "" ]
then
  BUILDBOX_BRANCH="master"
fi

# Do we need to do a git checkout?
if [ ! -d ".git" ]
then
  echo '--- cloning repository'

  buildbox-run "git clone "$BUILDBOX_REPO" . -qv"
else
  echo '--- updating repository'

  buildbox-run "git clean -fdq"
  buildbox-run "git fetch -q"
fi

# Only reset to the branch if we're not on a tag
if [ "$BUILDBOX_TAG" == "" ]
then
buildbox-run "git reset --hard origin/$BUILDBOX_BRANCH"
fi

buildbox-run "git checkout -qf \"$BUILDBOX_COMMIT\""

# Setup bundler to install gems into the cache directory
export BUNDLE_PATH="$BUILDBOX_CACHE_DIRECTORY/bundler"

# Point ruby gems to include the bundle cache directory
export GEM_PATH="$BUNDLE_PATH:$GEM_PATH"

echo "--- running $BUILDBOX_SCRIPT_PATH"

if [ "$BUILDBOX_SCRIPT_PATH" == "" ]
then
  echo "ERROR: No script path has been set for this project. Please go to \"Project Settings\" and add the path to your build script"
  exit 1
else
  ."/$BUILDBOX_SCRIPT_PATH"
  EXIT_STATUS=$?
fi

if [ "$BUILDBOX_ARTIFACT_PATHS" != "" ]
then
  # Make sure the buildbox-artifact binary is in the right spot.
  if [ ! -f $BUILDBOX_DIR/buildbox-artifact ]
  then
    echo >&2 "ERROR: buildbox-artifact could not be found in $BUILDBOX_DIR"
    exit 1
  fi

  # If you want to upload artifacts to your own server, uncomment the lines below
  # and replace the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY with keys to your
  # own bucket.
  # export AWS_SECRET_ACCESS_KEY=yyy
  # export AWS_ACCESS_KEY_ID=xxx
  # buildbox-artifact upload "$BUILDBOX_ARTIFACT_PATHS" "s3://name-of-your-s3-bucket/$BUILDBOX_JOB_ID" --url $BUILDBOX_AGENT_API_URL

  # By default we silence the buildbox-artifact build output. However, if you'd like to see
  # it in your logs, remove the: > /dev/null 2>&1 from the end of the line.
  $BUILDBOX_DIR/buildbox-artifact upload "$BUILDBOX_ARTIFACT_PATHS" --url $BUILDBOX_AGENT_API_URL > /dev/null 2>&1
  buildbox-exit-if-failed $?
fi

exit $EXIT_STATUS
