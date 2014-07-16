```
  _           _ _     _ _                                        [ ]
 | |         (_) |   | | |                                 [ ][ ][ ]     \  /
 | |__  _   _ _| | __| | |__   _____  __      +       __[ ][ ][ ][ ][ ]__/ /
 | '_ \| | | | | |/ _\` | '_ \ / _ \ \/ /   ++++++   ~~\~~~~~~~~~~~~~~~~~~~/~~
 | |_) | |_| | | | (_| | |_) | (_) >  <       +        \_____.           /
 |_.__/ \__,_|_|_|\__,_|_.__/ \___/_/\_\                \_______________/
```

The Builbdox Docker toolset allows you to have agents start/stop within Docker
containers.

**Note: This project should be considered alpha, and will probably change soon.
Feel free to hack and poke around, but it's not quite ready for production use just yet.**

### How does it work?

When you run the `buildbox-docker` command, it will monitor the agent you specify
on Buildbox and look for new jobs for it to perform. When a new job becomes a
available, it will boot the `buildbox-agent` process inside the container, and force
it to run the job. When the job finishes, the container shuts down, and the `buildbox-docker`
tool will start looking for new work again.

### Setup

#### Installing Docker (Ubuntu 64-bit only)

Source: http://docs.docker.io/installation/ubuntulinux/#ubuntu-trusty-1404-lts-64-bit

```bash
curl -s https://get.docker.io/ubuntu/ | sudo sh
```

#### Setting up buildbox-docker

```bash
# Get the image
sudo docker pull buildbox/base

# Install buildbox-docker
bash -c "`curl -sL https://raw.github.com/buildbox/buildbox-docker/master/install.sh`"

# Run the process
~/.buildbox/buildbox-docker --access-token [buildbox-agent-access-token]
```

#### Building the image locally

```bash
# Clone and enter the repo
git clone https://github.com/buildbox/buildbox-docker
cd buildbox-docker

# Build and tag the image
sudo docker build --tag "buildbox/base" .
```

#### Running on OSX

The Docker Client can run on OSX, but note that the containers dont, they only support being run on Linux.

So, in the intermin, if you wan't to run `buildbox-docker` from OSX, you'll need to install a Linux virtual machine. We use Vagrant for tis.

The first step is to get VirtualBox installed (needs version 4.2) https://www.virtualbox.org/wiki/Download_Old_Builds_4_2

```bash
# Now install Vagrant, see here.
# See: http://www.vagrantup.com/downloads.html

# Install the docker tool
brew tap homebrew/binary
brew install docker

# Setting up the vargant machine
git clone https://github.com/buildbox/buildbox-docker
cd buildbox-docker
vagrant up
vagrant ssh

# Now we've SSH'd into the machine, we can install docker
curl -s https://get.docker.io/ubuntu/ | sudo sh

# You can either pull the image...
sudo docker pull buildbox/base

# Or build it yourself
cd /vagrant
sudo docker build --tag "buildbox/base" .

# After setting up docker, we need to change how the docker daemon is run.
# By default, the daemon runs on a unix socket, but we can't access that from OSX. So we need to change it
# to run on a TCP socket, and foward ports in Vagrant.
#
# Warning: Don't run this on a production system. You don't want to expose docker like this there.
sudo sed -i 's/^#DOCKER_OPTS.*/DOCKER_OPTS="-H tcp:\/\/0.0.0.0:4243 -H unix:\/\/var\/run\/docker.sock"/g' /etc/default/docker

# Now restart the VM
sudo shutdown -r now

# Now that we've restarted, you should be able to from OSX:
#
#   export DOCKER_HOST=tcp://0.0.0.0:4243
#   docker ps
#
# and inside the VM:
#
#   sudo docker ps
```

#### Development

Although `buildbox-docker` does run on OSX, I've found that the STDOUT from
`docker run` doesn't contain all the output, it usually skips. So when I'm
developing `buildbox-docker`, my workflow looks something like this:

1. Edit main.go
2. `./scripts/compile.sh`

Then I switch to the Vagrant VM:

1. `vagrant ssh`
2. `cd /vargrant`
3. `./pkg/buildbox-docker --access-token "..."`

When I'm making changes to the `Dockerfile`, I sometimes want to get a bash
terminal of the image. I can do that with the following command from either
OSX of the Vagrant VM.

```bash
sudo docker run -i -t buildbox/base /bin/bash
```
