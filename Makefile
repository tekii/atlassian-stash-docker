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
TAG:=tekii/atlassian-stash
RUN_USER:=daemon
RUN_GROUP:=daemon


##
## M4
##
M4= $(shell which m4)
M4_FLAGS= -P \
	-D __VERSION__=$(STASH_VERSION) \
	-D __LOCATION__=$(LOCATION) \
	-D __TARBALL__=$(TARBALL) \
	-D __INSTALL__=$(STASH_INSTALL) \
	-D __HOME__=$(STASH_HOME) \
	-D __USER__=$(RUN_USER) -D __GROUP__=$(RUN_GROUP) \
	-D __TAG__=$(TAG)

$(TARBALL):
	wget $(LOCATION)/$(TARBALL)

$(PATCHED_DIST): $(STASH_TARBALL) config.patch
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
	docker build -t $(TAG) .

PHONY+= run
run: #image
	docker run -p 7990:7990 -p 7991:7991 -p 7999:7999 -e "CATALINA_OPTS=-Dtekii.contextPath=/stash" -v $(shell pwd)/volume:$(STASH_HOME) $(TAG)

PHONY += push-to-google
push-to-google: image
	docker tag $(TAG) gcr.io/mrg-teky/atlassian-stash
	gcloud docker push gcr.io/mrg-teky/atlassian-stash

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
