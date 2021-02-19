#!/bin/bash

PUB_IP=$(ifconfig eth0 | grep inet | awk '{ print($2) }' | sed 's/addr://g')
#PUB_IP=10.0.0.55
sed -i.original 's/ext-sip-ip" value="auto-nat"/ext-sip-ip" value="'$PUB_IP'"/g; s/ext-rtp-ip" value="auto-nat"/ext-rtp-ip" value="'$PUB_IP'"/g' /etc/freeswitch/sip_profiles/external.xml
/usr/bin/freeswitch -u freeswitch -g freeswitch -c