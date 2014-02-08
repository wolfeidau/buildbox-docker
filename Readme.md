# Buildbox Docker

The Builbdox Docker toolset allows you to have agents start/stop within Docker containers.

## How secure is this?

Docker containers are super secure. See: http://blog.docker.io/2013/08/containers-docker-how-secure-are-they/

## Running on OSX

Install VirtualBox (needs version 4.2) https://www.virtualbox.org/wiki/Download_Old_Builds_4_2

```
# docker only works with 64bit ubuntu
vagrant init raring32 http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-i386-vagrant-disk1.box
vagrant ssh
```

## Setting up the host machine (Ubuntu 64-bit only)

Source: http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring-13-04-and-saucy-13-10-64-bit

```
sudo apt-get update
sudo apt-get install linux-image-extra-`uname -r`

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main\
       > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install lxc-docker
```
