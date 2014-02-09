FROM ubuntu:precise

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

# Essentials
RUN apt-get install -y curl git build-essential

# The user the builds will run as
RUN sudo useradd buildbox --shell /bin/bash --create-home

# Setup the agent
RUN mkdir -p /home/buildbox/.buildbox
RUN DESTINATION=/home/buildbox/.buildbox bash -c "`curl -sL https://agent.buildbox.io/install.sh`"
RUN chown -R buildbox:buildbox /home/buildbox/.buildbox
RUN ln -s /home/buildbox/.buildbox/buildbox-agent /usr/local/bin

# Drop privileges so commands can only be run as buildbox
ENV HOME /home/buildbox
WORKDIR /home/buildbox
USER buildbox
