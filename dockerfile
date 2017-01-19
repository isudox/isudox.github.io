FROM node:6-onbuild
MAINTAINER sudoz <me@isudox.com>

EXPOSE 8888
RUN apt-get update \
    && apt-get install -y python-pip \
    && pip install shadowsocks
