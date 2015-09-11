#
# STASH Dockerfile
# 
FROM tekii/debian-server-jre

MAINTAINER Pablo Jorge Eduardo Rodriguez <pr@tekii.com.ar>

LABEL version=3.11.2

COPY config.patch /opt/atlassian/stash/

RUN apt-get update && \
    apt-get install --assume-yes --no-install-recommends git wget patch ca-certificates && \
    wget -q -O - https://www.atlassian.com/software/stash/downloads/binary/atlassian-stash-3.11.2.tar.gz | tar -xz --strip=1 -C /opt/atlassian/stash && \
    cd /opt/atlassian/stash && patch -p1 -i config.patch && cd - && \
    mkdir --parents /opt/atlassian/stash/conf/Catalina && \
    chmod --recursive 700 /opt/atlassian/stash/conf/Catalina && \
    chmod --recursive 700 /opt/atlassian/stash/logs && \
    chmod --recursive 700 /opt/atlassian/stash/temp && \
    chmod --recursive 700 /opt/atlassian/stash/work && \
    chown --recursive daemon:daemon /opt/atlassian/stash/logs && \
    chown --recursive daemon:daemon /opt/atlassian/stash/temp && \
    chown --recursive daemon:daemon /opt/atlassian/stash/work && \
    chown --recursive daemon:daemon /opt/atlassian/stash/conf && \    
    apt-get purge --assume-yes wget patch && \
    apt-get clean autoclean && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

#
ENV STASH_HOME=/var/atlassian/application-data/stash
# override by conf/bin/user.sh
ENV STASH_USER=daemon

# default value for the tomcat contextPath, to be override by kubernetes
ENV CATALINA_OPTS="-Dtekii.contextPath="
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

ENTRYPOINT ["/opt/atlassian/stash/bin/start-stash.sh", "-fg"]

