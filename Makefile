SHELL := /usr/bin/env bash

#NDEF = $(if $(value $(1)),,$(error $(1) not set))

NO_COLOR=$(shell echo -e "\e[m")
WARN_COLOR=$(shell echo -e "\e[1;7m")
ERROR_COLOR=$(shell echo -e "\e[1;31m")
OK_COLOR=$(shell echo -e "\e[1;34m")
HIGHLIGHT_COLOR=$(shell echo -e "\e[93;1m")
export IFACE=$$(netstat -rn | grep default | grep -v "tun" | awk '{ print $$4 }')
export IP_ADD=$$(ifconfig $(IFACE)| grep "inet "| head -n 1| cut -d" " -f2)

report_success = "$(OK_COLOR)RESULT:$(NO_COLOR) $(HIGHLIGHT_COLOR)$1$(NO_COLOR) $2 Success"

report_failure = "$(ERROR_COLOR)RESULT: $(HIGHLIGHT_COLOR)$1$(NO_COLOR) $2 Failed, exiting...$(ERROR_COLOR)"

.PHONY: init validate apply clean

help:
	@echo ""
	@echo "This makefile:"
	@echo "    - "make build": Build the actual server with the config."
	@echo "    - "make clean": Will remove the image"
	@echo "    - "make run": start the image (freeswitch)"
	@echo ""

all: enter

build:
	@echo "$(WARN_COLOR)WARNING:$(NO_COLOR) Building freeSWITCH"
	@docker build -t fs-docker . && echo $(call report_success,"freeSWITCH Server","Build") || (echo $(call report_failure,"freeSWITCH Server","Build") && exit -1)

enter:
	@docker exec -it `docker ps | grep "fs-docker" | cut -d" " -f1` /bin/bash

enter_fs:
	@docker exec -it `docker ps | grep "fs-docker" | cut -d" " -f1` /bin/bash -c fs_cli

run:
	@docker run -d -it -p $(IP_ADD):5088:5088/udp \
		-p $(IP_ADD):32000-32100:32000-32100/udp \
		-e PUBLIC_IP=$(IP_ADD) \
		--name freeswitch \
		-v ${PWD}/config:/etc/freeswitch fs-docker:latest #--entrypoint=/bin/bash

clean:
	@docker rm $$(docker ps -a | grep fs-docker | cut -d" " -f1)
