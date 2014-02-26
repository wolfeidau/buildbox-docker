#!/bin/bash
set -e
set -x

echo '--- environmnet'
env | grep BUILDBOX

echo '--- starting services'
sudo /etc/init.d/postgresql start
sudo /etc/init.d/redis start

echo '--- setup ssh'
echo "$BUILDBOX_AGENT_SSH_PRIVATE_KEY" >> ~/.ssh/id_rsa
echo "$BUILDBOX_AGENT_SSH_PUBLIC_KEY" >> ~/.ssh/id_rsa.pub
chmod 0600 ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa.pub

echo '--- setting up repo'
# Create the build directory
BUILD_DIR="tmp/$BUILDBOX_AGENT_NAME/$BUILDBOX_PROJECT_SLUG"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Do we need to do a git checkout?
if [ ! -d ".git" ]; then
  git clone "$BUILDBOX_REPO" . -qv --depth 20
fi

git clean -fdq
git fetch -q
git reset --hard origin/master
git checkout -qf "$BUILDBOX_COMMIT"

echo "--- running $BUILDBOX_SCRIPT_PATH"
."/$BUILDBOX_SCRIPT_PATH"
