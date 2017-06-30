#
# BITBUCKET Dockerfile
#
FROM gcr.io/mrg-teky/jre

MAINTAINER Pablo Jorge Eduardo Rodriguez <pr@tekii.com.ar>

LABEL version=5.1.2

COPY config.patch /opt/atlassian/stash/
COPY docker-entrypoint.sh /opt/atlassian/stash/bin/

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get install --assume-yes --no-install-recommends wget patch && \
    echo "start downloading and decompressing https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-5.1.2.tar.gz" && \
    wget -q -O - https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-5.1.2.tar.gz | tar -xz --strip=1 -C /opt/atlassian/stash && \
    echo "end downloading and decompressing." && \
    cd /opt/atlassian/stash && patch -p1 -i config.patch && cd - && \
    chmod --recursive 700 /opt/atlassian/stash/ && \
    chmod u+x /opt/atlassian/stash/bin/docker-entrypoint.sh && \
    chown --recursive daemon:daemon /opt/atlassian/stash/ && \
    apt-get -t jessie-backports install git-core --assume-yes --no-install-recommends && \
    apt-get purge --assume-yes wget patch && \
    apt-get clean autoclean && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/
#
ENV BITBUCKET_HOME=/var/atlassian/application-data/stash
ENV BITBUCKET_INSTALL_DIR=/opt/atlassian/stash
# override by conf/bin/user.sh
ENV BITBUCKET_USER=daemon
# default value for the tomcat contextPath, to be override by kubernetes
#
ENV JAVA_OPTS="-Datlassian.plugins.enable.wait=300"


# you must "chown __USER__.__GROUP__ .' this directory in the host in
# order to allow the jira user to write in it.
VOLUME /var/atlassian/application-data/stash
# HTTP Port
EXPOSE 7990
# HTTPS Proxy Port
EXPOSE 7991
# SSH Port
EXPOSE 7999
#
USER daemon:daemon

WORKDIR /var/atlassian/application-data/stash

ENTRYPOINT ["/opt/atlassian/stash/bin/docker-entrypoint.sh"]
