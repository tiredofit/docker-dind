FROM docker:dind
MAINTAINER Dave Conroy <dave at tiredofit dot ca>

## Add a couple packages to make life easier
ENV ZABBIX_HOSTNAME=docker-dind

### Zabbix Pre Installation steps
   RUN addgroup zabbix && \
       adduser -S \
               -D -G zabbix \
               -h /var/lib/zabbix/ \
           zabbix && \
       mkdir -p /etc/zabbix && \
       mkdir -p /etc/zabbix/zabbix_agentd.conf.d && \
       mkdir -p /var/lib/zabbix && \
       mkdir -p /var/lib/zabbix/enc && \
       mkdir -p /var/lib/zabbix/modules && \
       chown --quiet -R zabbix:root /var/lib/zabbix && \
       apk update && \
       apk add \
            coreutils \
            libssl1.0  && \

       rm -rf /var/cache/apk/* && \
       mkdir -p /assets/cron

  ARG MAJOR_VERSION=3.4
  ARG ZBX_VERSION=${MAJOR_VERSION}

### Zabbix Compilation
   RUN apk update && \
       apk add ${APK_FLAGS_DEV} --virtual zabbix-build-dependencies \
               alpine-sdk \
               automake \
               autoconf \
               openssl-dev \
               git && \

       cd /tmp/ && \
       git clone --verbose --progress https://github.com/zabbix/zabbix/ && \
       cd zabbix && \
       git fetch origin && \
       git checkout trunk && \
       sed -i "s/{ZABBIX_REVISION}/trunk/g" include/version.h && \
       ./bootstrap.sh 1>/dev/null && \
       ./configure \
               --prefix=/usr \
               --silent \
               --sysconfdir=/etc/zabbix \
               --libdir=/usr/lib/zabbix \
               --datadir=/usr/lib \
               --enable-agent \
               --enable-ipv6 \
               --enable-static && \
       make -j"$(nproc)" -s 1>/dev/null && \
       cp src/zabbix_agent/zabbix_agentd /usr/sbin/zabbix_agentd && \
       cp src/zabbix_sender/zabbix_sender /usr/sbin/zabbix_sender && \
       cp conf/zabbix_agentd.conf /etc/zabbix && \
       mkdir -p /etc/zabbix/zabbix_agentd.conf.d && \
       mkdir -p /var/log/zabbix && \
       chown -R zabbix:root /var/log/zabbix && \
       chown --quiet -R zabbix:root /etc/zabbix && \
       cd /tmp/ && \
       rm -rf /tmp/zabbix/ && \
       apk del --purge \
               zabbix-build-dependencies coreutils libssl1.0
       

   ADD /install/zabbix /etc/zabbix/

## Add other applications for ease of use
   RUN apk update && \
       apk add \
           bash \
           curl \
           less \
           logrotate \
           nano \
           tzdata \
           vim \
           && \
       rm -rf /var/cache/apk/* && \
       cp -R /usr/share/zoneinfo/America/Vancouver /etc/localtime && \
       echo 'America/Vancouver' > /etc/timezone && \
       mkdir -p /assets/cron

### Files Addition
  ADD install /

### Entrypoint Configuration
  ENTRYPOINT ["/init"]

