##
## STASH 
##
STASH_VERSION:=3.11.2
TARBALL:=atlassian-stash-$(STASH_VERSION).tar.gz
LOCATION:=https://www.atlassian.com/software/stash/downloads/binary
ORIGINAL_INSTALL:=original
PATCHED_INSTALL:=patched
STASH_HOME:=/var/atlassian/application-data/stash
STASH_INSTALL:=/opt/atlassian/stash
DOCKER_TAG:=tekii/atlassian-stash-selfsigned-ca
RUN_USER:=daemon
RUN_GROUP:=daemon


##
## M4
##
M4= $(shell which m4)
M4_FLAGS= -P \
	-D __VERSION__=$(STASH_VERSION) \
	-D __DOWNLOAD_URL__=$(LOCATION)/$(TARBALL) \
	-D __INSTALL__=$(STASH_INSTALL) \
	-D __HOME__=$(STASH_HOME) \
	-D __USER__=$(RUN_USER) -D __GROUP__=$(RUN_GROUP) \
	-D __DOCKER_TAG__=$(DOCKER_TAG)

$(TARBALL):
	wget $(LOCATION)/$(TARBALL)
#	md5sum --check $(JDK_TARBALL).md5

$(STASH_PATCHED_DIST): $(STASH_TARBALL) config.patch
	mkdir -p $@
	tar zxvf $(STASH_TARBALL) -C $@ --strip-components=1
	patch -p0 -i config.patch

#.SECONDARY
Dockerfile: Dockerfile.m4 Makefile
	$(M4) $(M4_FLAGS) $< >$@


PHONY += update-patch
update-patch:
#	mkdir ORIGINAL_INSTALL
#	mkdir PATCHED_INSTALL
#	tar zxvf $(TARBALL) -C original --strip-components=1
	diff -ruN -p1 $(ORIGINAL_INSTALL)/ $(PATCHED_INSTALL)/ > config.patch; [ $$? -eq 1 ]

PHONY += image
image: Dockerfile config.patch
	docker build -t $(DOCKER_TAG) .

PHONY+= run
run: #image
	docker run -p 7990:7990 -p 7991:7991 -p 7999:7999 -e "CATALINA_OPTS=-Dtekii.contextPath=/stash" -v $(shell pwd)/volume:$(STASH_HOME) $(DOCKER_TAG)


PHONY+= push-to-docker
push-to-docker: image
	docker push $(DOCKER_TAG)

PHONY += push-to-google
push-to-google: image
	docker tag $(DOCKER_TAG) gcr.io/mrg-teky/jira:$(STASH_VERSION)
	gcloud docker push gcr.io/mrg-teky/jira:$(STASH_VERSION)

PHONY += clean
clean:
	rm -rf $(STASH_ROOT)
	rm -f Dokerfile	

PHONY += realclean
realclean: clean
	rm -f $(STASH_TARBALL)

PHONY += all
all: $(JDK_TARBALL)

.PHONY: $(PHONY)
.DEFAULT_GOAL := all
