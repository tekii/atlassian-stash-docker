#
# BITBUCKET Dockerfile
#
FROM gcr.io/mrg-teky/jre

MAINTAINER Pablo Jorge Eduardo Rodriguez <pr@tekii.com.ar>

LABEL version=__VERSION__

m4_dnl ADD  __TARBALL__  __INSTALL__/
COPY config.patch __INSTALL__/
COPY docker-entrypoint.sh __INSTALL__/bin/

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get install --assume-yes --no-install-recommends wget patch && \
    echo "start downloading and decompressing __LOCATION__/__TARBALL__" && \
    wget -q -O - __LOCATION__/__TARBALL__ | tar -xz --strip=1 -C __INSTALL__ && \
    echo "end downloading and decompressing." && \
    cd __INSTALL__ && patch -p1 -i config.patch && cd - && \
    chmod --recursive 700 __INSTALL__/ && \
    chmod u+x __INSTALL__/bin/docker-entrypoint.sh && \
    chown --recursive __USER__:__GROUP__ __INSTALL__/ && \
    apt-get -t jessie-backports install git-core --assume-yes --no-install-recommends && \
    apt-get purge --assume-yes wget patch && \
    apt-get clean autoclean && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/
#
ENV BITBUCKET_HOME=__HOME__
ENV BITBUCKET_INSTALL_DIR=__INSTALL__
# override by conf/bin/user.sh
ENV BITBUCKET_USER=__USER__
# default value for the tomcat contextPath, to be override by kubernetes
m4_dnl ENV CATALINA_OPTS="-Dtekii.contextPath="
#
ENV JAVA_OPTS="-Datlassian.plugins.enable.wait=300"
m4_dnl ENV SERVER_SECURE=true
m4_dnl ENV SERVER_SCHEME=https
m4_dnl ENV SERVER_PROXY_PORT=443
m4_dnl ENV SERVER_PROXY_NAME=tekii.com.ar

m4_dnl ENV JVM_MINIMUM_MEMORY=512m
m4_dnl ENV JVM_MAXIMUM_MEMORY=768m
m4_dnl ENV JVM_MAXIMUM_MEMORY=512m

# you must "chown __USER__.__GROUP__ .' this directory in the host in
# order to allow the jira user to write in it.
VOLUME __HOME__
# HTTP Port
EXPOSE 7990
# HTTPS Proxy Port
EXPOSE 7991
# SSH Port
EXPOSE 7999
#
USER __USER__:__GROUP__

WORKDIR __HOME__

ENTRYPOINT ["__INSTALL__/bin/docker-entrypoint.sh"]
