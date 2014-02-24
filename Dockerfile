FROM ubuntu:precise

# Upgrade and update all the things
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y --force-yes upgrade

# Set up the environment
ENV DEBIAN_FRONTEND noninteractive
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Fix encoding-related bug
# https://bugs.launchpad.net/ubuntu/+source/lxc/+bug/813398
RUN apt-get -qy install language-pack-en
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# =====================================
#
# Buildbox
#
# =====================================

# Setup the user
RUN sudo useradd buildbox --shell /bin/bash --create-home

# Install the agent
RUN apt-get install -y --force-yes curl
RUN mkdir -p /home/buildbox/.buildbox
RUN DESTINATION=/home/buildbox/.buildbox bash -c "`curl -sL https://agent.buildbox.io/install.sh`"
ADD bootstrap.sh /home/buildbox/.buildbox/bootstrap.sh
RUN chmod +x /home/buildbox/.buildbox/bootstrap.sh
RUN chown -R buildbox:buildbox /home/buildbox/.buildbox
RUN ln -s /home/buildbox/.buildbox/buildbox-agent /usr/local/bin

# Allow passwordless sudo
RUN sudo usermod -a -G sudo buildbox
RUN sudo usermod -a -G sudo buildbox
RUN echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers


# =====================================
#
# Node.js
#
# =====================================

RUN apt-get install -y --force-yes python-software-properties
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN apt-get update -y
RUN apt-get install -y --force-yes nodejs

# =====================================
#
# Rbenv
#
# =====================================

RUN apt-get install -y --force-yes build-essential curl openssl libssl-dev git-core vim tklib zlib1g-dev libssl-dev libreadline-gplv2-dev libxml2 libxml2-dev libxslt1-dev
RUN git clone https://github.com/sstephenson/rbenv.git /home/buildbox/.rbenv
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/buildbox/.profile
RUN echo 'eval "$(rbenv init -)"' >> /home/buildbox/.profile
RUN git clone https://github.com/sstephenson/ruby-build.git /home/buildbox/.rbenv/plugins/ruby-build
RUN echo 'gem: --no-rdoc --no-ri' >> /home/buildbox/.gemrc
RUN chown -R buildbox:buildbox /home/buildbox
RUN su buildbox /bin/bash --login -c "rbenv install 2.1.0 && rbenv global 2.1.0 && gem install bundler && rbenv rehash"

# =====================================
#
# PostgreSQL
#
# =====================================

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
# of PostgreSQL, `9.3`.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update

# Install `python-software-properties`, `software-properties-common` and PostgreSQL 9.3
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get -y --force-yes -q install python-software-properties software-properties-common
RUN apt-get -y --force-yes -q install libpq-dev postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3

# Recreate the cluster to be UTF8
RUN service postgresql stop
RUN pg_dropcluster --stop 9.3 main
RUN pg_createcluster -e UTF8 9.3 main

# Note: The official Debian and Ubuntu images automatically `apt-get clean`
# after each `apt-get`

# Add in our custom pg_hba.conf
ADD postgresql/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf

# Set the PGUSER env variable
ENV PGDATA /var/lib/postgresql/9.3/main
ENV PGHOST localhost
ENV PGUSER postgres
ENV PGPORT 5432
ENV PGLOG /var/log/postgresql/postgresql-9.3-main.log
# ENV PGHOME=$PGHOME

# =====================================
#
# Defaults
#
# =====================================

# Drop privileges so commands can only be run as buildbox
ENV HOME /home/buildbox
WORKDIR /home/buildbox
USER buildbox
