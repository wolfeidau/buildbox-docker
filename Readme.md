# Buildbox Docker

The Builbdox Docker toolset allows you to have agents start/stop within Docker containers.

### How secure is this?

Docker containers are super secure. See: http://blog.docker.io/2013/08/containers-docker-how-secure-are-they/

### Running on OSX

Installing docker is pretty easy:

```
brew tap homebrew/binary
brew install docker
```

Install VirtualBox (needs version 4.2) https://www.virtualbox.org/wiki/Download_Old_Builds_4_2

```
vagrant up
vagrant ssh

# After setting up vagrant using the steps below, we need to change how the docker daemon is run.
# By default, the daemon runs on a unix socker, but we can't access that from OSX. So if we change it
# to run on a TCP socker, and foward ports in Vagrant, it should 'just work'
#
# Warning: Don't run this on a production system. You don't want to expose docker like this there.
sudo sed -i 's/^#DOCKER_OPTS.*/DOCKER_OPTS="-H tcp:\/\/0.0.0.0:4243 -H unix:\/\/var\/run\/docker.sock"/g' /etc/default/docker

# Now you can restat, and you should be able to:
#
#   docker -H tcp://0.0.0.0:4243 ps
#
# from OSX and
#
#   sudo docker ps
#
# on the VM
```

### Setting up the host machine (Ubuntu 64-bit only)

Source: http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring-13-04-and-saucy-13-10-64-bit

```
# Update and install some stuff that docker needs
sudo apt-get update
sudo apt-get -y install linux-image-extra-`uname -r`

# Install docker
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get -y install lxc-docker

# If you're on OSX, this is the part where we hack . See above for more details.

# Forces a reboot after updating all the things
sudo shutdown -r now
```
