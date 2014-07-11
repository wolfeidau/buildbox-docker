#!/bin/bash
#
# You can install the Buildbox Agent with the following:
#
#   bash -c "`curl -sL https://raw.github.com/buildboxhq/buildbox-docker/master/install.sh`"
#
# For more information, see: https://github.com/buildboxhq/buildbox-docker

COMMAND="bash -c \"\`curl -sL https://raw.github.com/buildboxhq/buildbox-docker/master/install.sh\`\""

set -e

echo -e "\033[33m
  _           _ _     _ _                                        [ ]
 | |         (_) |   | | |                                 [ ][ ][ ]     \  /
 | |__  _   _ _| | __| | |__   _____  __      +       __[ ][ ][ ][ ][ ]__/ /
 | '_ \| | | | | |/ _\` | '_ \ / _ \ \/ /    +++++   ~~\~~~~~~~~~~~~~~~~~~~/~~
 | |_) | |_| | | | (_| | |_) | (_) >  <       +        \_____.           /
 |_.__/ \__,_|_|_|\__,_|_.__/ \___/_/\_\                \_______________/\033[0m

-- https://buildbox.io

Latest Version: \033[35mv0.1-alpha.3\033[0m"

UNAME=`uname -sp | awk '{print tolower($0)}'`

if [[ ($UNAME == *"mac os x"*) || ($UNAME == *darwin*) ]]
then
  PLATFORM="darwin"
else
  PLATFORM="linux"
fi

if [[ ($UNAME == *x86_64*) || ($UNAME == *amd64*) ]]
then
  ARCH="amd64"
else
  ARCH="386"
fi

# Allow custom setting of the destination
if [ -z "$DESTINATION" ]; then
  # But default to the home directory
  DESTINATION="$HOME/.buildbox"
  mkdir -p $DESTINATION
fi

if [ ! -w "$DESTINATION" ]
then
  echo -e "\n\033[31mUnable to write to destination \`$DESTINATION\`\n\nYou can change the destination by running:\n\nDESTINATION=/my/path $COMMAND\033[0m\n"
  exit 1
fi

echo -e "Destination: \033[35m$DESTINATION\033[0m"

# Download and unzip the file to the destination
FILE=$DESTINATION/buildbox-docker
URL="https://github.com/buildboxhq/buildbox-docker/releases/download/v0.1-alpha.2/buildbox-docker-$PLATFORM-$ARCH.gz"
echo -e "\nDownloading $URL"

if command -v wget >/dev/null
then
  wget -qO- $URL | zcat > $FILE
else
  curl -sL $URL | zcat > $FILE
fi

# Make sure it's exectuable
chmod +x $FILE

echo -e "\n\033[32mSuccessfully installed to: $FILE\033[0m

You can now start the buildbox-docker tool like so:

  $DESTINATION/buildbox-docker --access-token token123

You can find your agent's Access Token on your Account Settings
page under \"Agents\".

The source code of the tool is available here:

  https://github.com/buildboxhq/buildbox-docker

If you have any questions or need a help getting things setup,
please email us at: hello@buildbox.io

Happy Building!"
