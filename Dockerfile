FROM ubuntu:precise

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

RUN sudo adduser buildbox --disabled-password --gecos "" --shell /bin/bash

RUN apt-get install -y curl

RUN mkdir -p /home/buildbox/.buildbox
RUN DESTINATION=/home/buildbox/.buildbox bash -c "`curl -sL https://agent.buildbox.io/install.sh`"
RUN chown -R buildbox:buildbox /home/buildbox/.buildbox
RUN ln -s /home/buildbox/.buildbox/buildbox-agent /usr/local/bin

USER buildbox
