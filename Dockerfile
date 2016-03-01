FROM debian
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y --no-install-recommends build-essential autoconf automake libtool zlib1g-dev libjpeg-dev libncurses-dev libssl-dev libcurl4-openssl-dev python-dev libexpat-dev libtiff-dev libx11-dev wget git

RUN echo "deb http://files.freeswitch.org/repo/deb/debian/ jessie main" > /etc/apt/sources.list.d/99FreeSWITCH.test.list
RUN wget -O - http://files.freeswitch.org/repo/deb/debian/key.gpg |apt-key add - 
RUN apt-get update
RUN DEBIAN_FRONTEND=none APT_LISTCHANGES_FRONTEND=none apt-get install -y --force-yes freeswitch-video-deps-most

RUN cd /usr/local/src; git config --global pull.rebase true
RUN cd /usr/local/src;  git clone https://freeswitch.org/stash/scm/fs/freeswitch.git freeswitch
RUN cd /usr/local/src/freeswitch; ./bootstrap.sh -j
RUN cd /usr/local/src/freeswitch; ./configure --prefix=/opt/freeswitch
RUN cd /usr/local/src/freeswitch; make; make install
RUN cd /usr/local/src/freeswitch; make all cd-sounds-install cd-moh-install; make samples
