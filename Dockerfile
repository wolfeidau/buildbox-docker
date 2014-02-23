FROM ubuntu:precise

# Upgrade and update all the things
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -y upgrade

# Make sure we're running the right LANG
RUN echo 'LANG="en_US.UTF-8"' >> /etc/profile
RUN echo 'LANGUAGE="en_US.UTF-8"' >> /etc/profile
RUN echo 'LC_ALL="en_US.UTF-8"' >> /etc/profile
RUN locale-gen "en_US.UTF-8"
RUN dpkg-reconfigure locales

# Changes the default umask for all users so members of the same
# group can write to the same folder
RUN echo "session optional pam_umask.so umask=002" >> /etc/pam.d/common-session
RUN echo "session optional pam_umask.so umask=002" >> /etc/pam.d/common-session-noninteractive

# The user the builds will run as
RUN sudo useradd buildbox --shell /bin/bash --create-home

# node.js
RUN apt-get install -y python-software-properties
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN apt-get update -y
RUN apt-get install -y nodejs

# rbenv
RUN apt-get install -y build-essential curl openssl libssl-dev git-core vim tklib zlib1g-dev libssl-dev libreadline-gplv2-dev libxml2 libxml2-dev libxslt1-dev
RUN git clone https://github.com/sstephenson/rbenv.git /home/buildbox/.rbenv
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/buildbox/.profile
RUN echo 'eval "$(rbenv init -)"' >> /home/buildbox/.profile
RUN git clone https://github.com/sstephenson/ruby-build.git /home/buildbox/.rbenv/plugins/ruby-build
RUN echo 'gem: --no-rdoc --no-ri' >> /home/buildbox/.gemrc
RUN chown -R buildbox:buildbox /home/buildbox
RUN su buildbox /bin/bash --login -c "rbenv install 2.1.0 && rbenv global 2.1.0"

# Drop privileges so commands can only be run as buildbox
ENV HOME /home/buildbox
WORKDIR /home/buildbox
USER buildbox
