# buildbox-docker

The Builbdox Docker toolset allows you to have agents start/stop within Docker
containers.

**Note: This project should be considered alpha, and will probably change soon. Feel free to hack and poke around, but it's not quite ready for production use just yet.**

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
# Update and install some stuff that docker needs
sudo apt-get update

# Ubuntu Precise 12.04 (LTS) (64-bit)
sudo apt-get install linux-image-generic-lts-`uname -r` linux-headers-generic-lts-`uname -r`

# Ubuntu Raring 13.04 and Saucy 13.10 (64 bit)
sudo apt-get -y install linux-image-extra-`uname -r`

# Install docker
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get -y install lxc-docker
```

#### Setting up buildbox-docker

```bash
# Get the repo
git clone https://github.com/buildboxhq/buildbox-docker
cd buildbox-docker

# Add SSH key pairs - generate or copy SSH keys into the "ssh" directory
ssh-keygen -t rsa -f ssh/id_rsa

# Build the image
docker build --rm .
docker tag [docker-image-id] buildboxhq/base

# Install buildbox-docker
bash -c "`curl -sL https://raw.github.com/buildboxhq/buildbox-docker/master/install.sh`"

# Run the process
buildbox-docker --access-token [buildbox-agent-access-token]
```

#### Running on OSX

Installing docker tool is pretty easy, however note that the containers don't _actaully_ run on OSX as it only works on Linux at the moment. You need to have Vagrant installed so we can bootup a linux virtual machine.

You'll also need VirtualBox installed (needs version 4.2) https://www.virtualbox.org/wiki/Download_Old_Builds_4_2

```bash
# Install the docker tool
brew tap homebrew/binary
brew install docker

# Get vargant installed
gem install vagrant

# Setting up the vargant machine
git clone https://github.com/buildboxhq/buildbox-docker
cd buildbox-docker
vagrant up
vagrant ssh

# Now you can follow the Linux steps above. Continue when that's done.

# After setting up docker, we need to change how the docker daemon is run.
# By default, the daemon runs on a unix socket, but we can't access that from OSX. So we need to change it
# to run on a TCP socket, and foward ports in Vagrant.
#
# Warning: Don't run this on a production system. You don't want to expose docker like this there.
sudo sed -i 's/^#DOCKER_OPTS.*/DOCKER_OPTS="-H tcp:\/\/0.0.0.0:4243 -H unix:\/\/var\/run\/docker.sock"/g' /etc/default/docker

# Now you can restat the vagarnt VM, and you should be able to from OSX:
#
#   export DOCKER_HOST=tcp://0.0.0.0:4243
#   docker ps
#
# and inside the VM:
#
#   sudo docker ps
```

#### Debugging

```
sudo docker run -i -t buildboxhq/base /bin/bash

sudo docker run -name testcontainer123 -i -t buildboxhq/base /bin/bash
sudo docker commit 040048f4ec52 testimage123
sudo docker run -i -u buildbox -w "/home/buildbox" -t testimage123 /bin/bash
```
