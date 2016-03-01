FROM debian:jessie

MAINTAINER davidcsi "david.villasmil@gmail.com"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y -qq && \
    apt-get install -y -qq curl

RUN curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -

RUN echo "deb http://files.freeswitch.org/repo/deb/freeswitch-1.6/ jessie main" > /etc/apt/sources.list.d/freeswitch.list
RUN apt-get update -y -qq && apt-get install -y -qq freeswitch-all freeswitch-all-dbg gdb supervisor

ENV DEBIAN_FRONTEND dialog
RUN apt-get clean

RUN rm -rf /etc/freeswitch/*
COPY ./conf /etc/freeswitch

COPY ./supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
EXPOSE 5060 5061 6080 5081
CMD ["/usr/bin/supervisord"]