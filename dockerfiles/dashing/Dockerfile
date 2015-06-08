FROM debian:jessie

MAINTAINER Mark Kinsman <marc.kinsman@mortenson.com>

# Disable frontend warnings
ENV DEBIAN_FRONTEND noninteractive

# Install Ruby and Node.js
RUN echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y make g++ ruby-full nodejs ca-certificates libmysqlclient-dev && \
    apt-get -y clean

RUN gem install bundle dashing
RUN mkdir /dashing && \
    dashing new dashing && \
    cd /dashing && bundle && \
    ln -s /dashing/dashboards /dashboards && \
    ln -s /dashing/jobs /jobs && \
    ln -s /dashing/public /public && \
    ln -s /dashing/widgets /widgets && \
    mkdir /dashing/config && \
    mv /dashing/config.ru /dashing/config/config.ru && \
    ln -s /dashing/config/config.ru /dashing/config.ru && \
    ln -s /dashing/config /config

COPY run.sh /

VOLUME ["/dashboards", "/jobs", "/config", "/public", "/widgets"]

ENV PORT 3030
EXPOSE $PORT
WORKDIR /dashing

CMD ["/run.sh"]
