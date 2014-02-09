FROM ubuntu:precise

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

RUN sudo adduser buildbox --disabled-password --gecos "" --shell /bin/bash
RUN sudo usermod -a -G sudo buildbox
RUN sudo usermod -a -G sudo buildbox

RUN echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

USER buildbox
