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

echo '--- setup environment'

# Boot up stuff that isn't by default started in the container
buildbox-run "sudo /etc/init.d/postgresql start"
buildbox-run "sudo /etc/init.d/redis start"

# Setup the SSH keys for this agent
echo "$BUILDBOX_AGENT_SSH_PRIVATE_KEY" >> ~/.ssh/id_rsa
echo "$BUILDBOX_AGENT_SSH_PUBLIC_KEY" >> ~/.ssh/id_rsa.pub
chmod 0600 ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa.pub

# This will return the location of this file. We assume that the buildbox-artifact
# tool is in the same folder. You can of course customize the locations
# and edit this file.
BUILDBOX_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create the build directory
BUILDBOX_BUILD_DIR="$BUILDBOX_AGENT_NAME/$BUILDBOX_PROJECT_SLUG"

buildbox-run "mkdir -p $BUILDBOX_BUILD_DIR"
buildbox-run "cd $BUILDBOX_BUILD_DIR"

# Do we need to do a git checkout?
if [ ! -d ".git" ]
then
  buildbox-run "git clone "$BUILDBOX_REPO" . -qv"
fi

buildbox-run "git clean -fdq"
buildbox-run "git fetch -q"
buildbox-run "git reset --hard origin/master"
buildbox-run "git checkout -qf \"$BUILDBOX_COMMIT\""

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
