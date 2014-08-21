#!/bin/bash
set -e
set -x

# Set Postgres related ENV variables
export PGDATA="/var/lib/postgresql/9.3/main"
export PGHOST="localhost"
export PGUSER="postgres"
export PGPORT="5432"
export PGLOG="/var/log/postgresql/postgresql-9.3-main.log"

# Setup the SSH keys for this agent
echo "$BUILDBOX_AGENT_SSH_PRIVATE_KEY" >> /home/buildbox/.ssh/id_rsa
echo "$BUILDBOX_AGENT_SSH_PUBLIC_KEY" >> /home/buildbox/.ssh/id_rsa.pub
chmod 0600 /home/buildbox/.ssh/id_rsa
chmod 0600 /home/buildbox/.ssh/id_rsa.pub
chown -R buildbox:buildbox /home/buildbox/.ssh

# Ensure the cache directory is owned by the buildbox user
chown -R buildbox:buildbox "$BUILDBOX_CACHE_DIRECTORY"

# Finally run the agent. We need to re-export the $BUILDBOX_CACHE_DIRECTORY as it's
# set by buildbox-docker, and wont' be preserved when we spawn a new session
# below.
su buildbox /bin/bash --login -c "BUILDBOX_CACHE_DIRECTORY=$BUILDBOX_CACHE_DIRECTORY ~/.buildbox/buildbox-agent run $BUILDBOX_JOB_ID --access-token $BUILDBOX_AGENT_ACCESS_TOKEN --url $BUILDBOX_AGENT_URL --debug"
