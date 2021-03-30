FROM debian:buster

LABEL MANTAINER=davidcsi/david.villasmil@gmail.com

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y -qq && \
    apt-get install -y -qq curl gnupg2 wget lsb-release

RUN wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add -
 
RUN echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
RUN echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

ENV DEBIAN_FRONTEND dialog
RUN apt-get update -y -qq 
RUN apt-get install -y freeswitch-meta-all gdb supervisor net-tools
RUN apt-get clean

RUN rm -rf /etc/freeswitch/*
#COPY ./conf /etc/freeswitch

COPY ./supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./startup.sh /startup.sh
EXPOSE 5060 5061 6080 5081
CMD ["/usr/bin/supervisord"]

# Build:
# sudo docker build -t davidv/telnyx-load-test-freeswitch:latest .
#
# Run:
# sudo docker run -v ${pwd}/conf:/etc/freeswitch --network=host -it davidv/telnyx-load-test-freeswitch:latest .
