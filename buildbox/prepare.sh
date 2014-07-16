#!/bin/bash
set -e
set -x

# Start MySQL
mysqld_safe &

# Start PostgreSQL
/etc/init.d/postgresql start

# Start Redis
/etc/init.d/redis start

# Bootup a XVFB
Xvfb :99 -ac > /dev/null 2>&1 & export DISPLAY=:99

# Setup the SSH keys for this agent
echo "$BUILDBOX_AGENT_SSH_PRIVATE_KEY" >> /home/buildbox/.ssh/id_rsa
echo "$BUILDBOX_AGENT_SSH_PUBLIC_KEY" >> /home/buildbox/.ssh/id_rsa.pub
chmod 0600 /home/buildbox/.ssh/id_rsa
chmod 0600 /home/buildbox/.ssh/id_rsa.pub
chown -R buildbox:buildbox /home/buildbox/.ssh

# Finally run the agent
su buildbox /bin/bash --login -c "~/.buildbox/buildbox-agent run $BUILDBOX_JOB_ID --access-token $BUILDBOX_AGENT_ACCESS_TOKEN --url $BUILDBOX_AGENT_URL --debug"
