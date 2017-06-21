##
## BITBUCKET
##
BITBUCKET_VERSION:=4.14.6
TARBALL:=atlassian-bitbucket-$(BITBUCKET_VERSION).tar.gz
LOCATION:=https://www.atlassian.com/software/stash/downloads/binary
ORIGINAL_INSTALL:=original-$(BITBUCKET_VERSION)
PATCHED_INSTALL:=patched-$(BITBUCKET_VERSION)
STASH_HOME:=/var/atlassian/application-data/stash
STASH_INSTALL:=/opt/atlassian/stash
TAG:=gcr.io/mrg-teky/atlassian-bitbucket
RUN_USER:=daemon
RUN_GROUP:=daemon

##
## M4
##
M4= $(shell which m4)
M4_FLAGS= -P \
	-D __VERSION__=$(BITBUCKET_VERSION) \
	-D __LOCATION__=$(LOCATION) \
	-D __TARBALL__=$(TARBALL) \
	-D __INSTALL__=$(STASH_INSTALL) \
	-D __HOME__=$(STASH_HOME) \
	-D __USER__=$(RUN_USER) -D __GROUP__=$(RUN_GROUP) \
	-D __TAG__=$(TAG)

$(TARBALL):
	wget $(LOCATION)/$(TARBALL)

$(ORIGINAL_INSTALL): $(TARBALL)
	mkdir -p $@
	tar zxvf $(TARBALL) -C $@ --strip-components=1

$(PATCHED_INSTALL): $(TARBALL) config.patch
	mkdir -p $@
	tar zxvf $(TARBALL) -C $@ --strip-components=1
	patch -p0 -i config.patch

#.SECONDARY
Dockerfile: Dockerfile.m4 Makefile
	$(M4) $(M4_FLAGS) $< >$@

cloudbuild.yaml: m4/cloudbuild.yaml Makefile
	$(M4) $(M4_FLAGS) $< >$@

PHONY += update-patch
update-patch:
#	mkdir ORIGINAL_INSTALL
#	mkdir PATCHED_INSTALL
#	tar zxvf $(TARBALL) -C original --strip-components=1
	diff -ruN -p1 $(ORIGINAL_INSTALL)/ $(PATCHED_INSTALL)/ > config.patch; [ $$? -eq 1 ]

PHONY += image
image: Dockerfile config.patch
	docker build --no-cache=false --rm=true --tag $(TAG):$(BITBUCKET_VERSION) .

PHONY+= run
run: #image
	docker run -p 7990:7990 -p 7991:7991 -p 7999:7999 -e "CATALINA_OPTS=-Dtekii.contextPath=/stash" -v $(shell pwd)/volume:$(STASH_HOME) $(TAG):$(BITBUCKET_VERSION)


PHONY += git-tag git-push
git-tag:
	-git tag -d gcr-$(BITBUCKET_VERSION)
	git tag gcr-$(BITBUCKET_VERSION)

git-push:
	-git push origin :refs/tags/gcr-$(BITBUCKET_VERSION)
	git push origin
	git push --tags origin

PHONY += clean
clean:
	rm -rf $(ORIGINAL_INSTALL) $(PATCHED_INSTALL)

PHONY += realclean
realclean: clean
	rm -f $(TARBALL)

PHONY += all
all: Dockerfile

.PHONY: $(PHONY)
.DEFAULT_GOAL := all
