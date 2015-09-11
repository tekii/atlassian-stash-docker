#
# STASH Dockerfile
# 
FROM tekii/debian-server-jre

MAINTAINER Pablo Jorge Eduardo Rodriguez <pr@tekii.com.ar>

LABEL version=__VERSION__

COPY config.patch __INSTALL__/

RUN apt-get update && \
    apt-get install --assume-yes --no-install-recommends git wget patch ca-certificates && \
    wget -q -O - __DOWNLOAD_URL__ | tar -xz --strip=1 -C __INSTALL__ && \
    cd __INSTALL__ && patch -p1 -i config.patch && cd - && \
    mkdir --parents __INSTALL__/conf/Catalina && \
    chmod --recursive 700 __INSTALL__/conf/Catalina && \
    chmod --recursive 700 __INSTALL__/logs && \
    chmod --recursive 700 __INSTALL__/temp && \
    chmod --recursive 700 __INSTALL__/work && \
    chown --recursive __USER__:__GROUP__ __INSTALL__/logs && \
    chown --recursive __USER__:__GROUP__ __INSTALL__/temp && \
    chown --recursive __USER__:__GROUP__ __INSTALL__/work && \
    chown --recursive __USER__:__GROUP__ __INSTALL__/conf && \    
    apt-get purge --assume-yes wget patch && \
    apt-get clean autoclean && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

#
ENV STASH_HOME=__HOME__
# override by conf/bin/user.sh
ENV STASH_USER=__USER__

# default value for the tomcat contextPath, to be override by kubernetes
ENV CATALINA_OPTS="-Dtekii.contextPath="
#
ENV JAVA_OPTS="-Datlassian.plugins.enable.wait=300"

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

ENTRYPOINT ["__INSTALL__/bin/start-stash.sh", "-fg"]
