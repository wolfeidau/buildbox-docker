# Buildbox Docker

The Builbdox Docker toolset allows you to have agents start/stop within Docker
containers.

### How does it work?

When you run the `buildbox-docker` command, it will monitor agents you specify
on Buildbox and look for new jobs for them to perform. When a new job becomes a
available, it will first make sure the container has been build, and then run the
bootstrap.sh script inside the container with all the correct ENV varaibles set.

### How secure is this?

Docker containers are super secure. See:
http://blog.docker.io/2013/08/containers-docker-how-secure-are-they/

### Setting up the image

```bash
docker build -rm .
docker tag [commit] buildboxhq/base
```

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

#   export DOCKER_HOST=tcp://0.0.0.0:4243
#   docker ps
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

# Ubuntu Raring 13.04 and Saucy 13.10 (64 bit)
sudo apt-get -y install linux-image-extra-`uname -r`

# Ubuntu Precise 12.04 (LTS) (64-bit)
sudo apt-get install linux-image-generic-lts-raring linux-headers-generic-lts-raring

# Install docker
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get -y install lxc-docker

# If you're on OSX, this is the part where we hack . See above for more details.

# Forces a reboot after updating all the things
sudo shutdown -r now
```
