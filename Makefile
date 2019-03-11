# Prerequisites are intentionally incomplete. See the README for how to use
# this.

# How many commits the git test repo should have. 5 has high chance of
# completing the git clone, 100 very little (will hit the bug).
N_COMMITS := 100

# A few cli tools are added to nix-shell for convenience, because --pure
# removes all globally installed tools.
CLI_TOOLS := less git

LIGHTTPD_BUILD_INPUTS := $(CLI_TOOLS) autoreconfHook pkgconfig pcre zlib #openldap
LIGHTTPD_CONFIGURE_FLAGS := --without-bzip2 --with-ldap CFLAGS=\"-I$(PWD)/openldap/_install/include -g3 -O0\" LDFLAGS="-L$(PWD)/openldap/_install/lib"
LIGHTTPD_SHELL := nix-shell --pure -p $(LIGHTTPD_BUILD_INPUTS)
 
OPENLDAP_BUILD_INPUTS := $(CLI_TOOLS) autoreconfHook pkgconfig groff
OPENLDAP_CONFIGURE_FLAGS := CFLAGS=\"-g3 -O0\"
OPENLDAP_SHELL := nix-shell --pure -p $(OPENLDAP_BUILD_INPUTS)

# For reproducible tests
GIT_ENV := GIT_AUTHOR_DATE="Thu Mar 7 16:26:21 2019 +0100" GIT_COMMITTER_DATE="Thu Mar 7 16:26:21 2019 +0100"

# Comment out to run without gdb
#LIGHTTPD_MAYBE_GDB := gdb -ex "set pagination off" -ex "directory lighttpd1.4" -ex run -args
#OPENLDAP_MAYBE_GDB := gdb -ex "set pagination off" -ex "directory openldap" -ex "handle SIGPIPE nostop" -ex run -args

help:
	@echo "Please see README"

init: openldap-fetch-source openldap-configure openldap-build lighttpd-fetch-source lighttpd-configure lighttpd-build create-git-repo

# lighttpd
lighttpd-shell:
	(cd lighttpd1.4 && $(LIGHTTPD_SHELL))

lighttpd-fetch-source:
	if [ -d lighttpd1.4 ]; then \
	    (cd lighttpd1.4 && git fetch) \
	else \
	    git clone https://git.lighttpd.net/lighttpd/lighttpd1.4.git; \
	fi

lighttpd-configure:
	(cd lighttpd1.4 && \
	 $(LIGHTTPD_SHELL) --run "./autogen.sh" && \
	 $(LIGHTTPD_SHELL) --run "export hardeningDisable=all; ./configure --prefix=$$PWD/_install $(LIGHTTPD_CONFIGURE_FLAGS)")

lighttpd-build:
	(cd lighttpd1.4 && \
	 $(LIGHTTPD_SHELL) --run "export hardeningDisable=all; make install")

lighttpd-run:
	$(LIGHTTPD_MAYBE_GDB) ./lighttpd1.4/_install/sbin/lighttpd -D -f ./lighttpd.conf

# openldap
openldap-shell:
	(cd openldap && $(OPENLDAP_SHELL))

openldap-fetch-source:
	if [ -d openldap ]; then \
	    (cd openldap && git fetch) \
	else \
	    git clone git://git.openldap.org/openldap.git; \
	fi

openldap-configure:
	(cd openldap && \
	 $(OPENLDAP_SHELL) --run "export hardeningDisable=all; ./configure --prefix=$$PWD/_install $(OPENLDAP_CONFIGURE_FLAGS)")

# openldap "make install" is very slow. Run directly from build dir?
openldap-build:
	(cd openldap && \
	 $(OPENLDAP_SHELL) --run "export hardeningDisable=all; make install")

# WARN: Runs with sudo to open port 389!
# NOTE: slapd -d 0 argument prevents forking, but is a NOP wrt. logging.
# Set -d -1 to enable all logging.
openldap-run:
	rm -rf tmp/var_db_openldap_test
	mkdir -p tmp/var_db_openldap_test
	./openldap/_install/sbin/slapadd -f ./slapd.conf -l ./ldap-db.ldif
	sudo $(OPENLDAP_MAYBE_GDB) ./openldap/_install/libexec/slapd -h 'ldap:///' -d 256 -f ./slapd.conf

# Remove the .git/index file at the end for deterministic repo hash (more or
# less)
create-git-repo:
	rm -rf ./git-repos/
	mkdir -p ./git-repos/repo1
	(cd ./git-repos/repo1 && \
	   git init && \
	   touch file && \
	   git add . && $(GIT_ENV) git commit -m "Initial commit" && \
	   for i in $$(seq $(N_COMMITS)); do \
	       echo i=$$i >file && $(GIT_ENV) git commit -m "Commit i=$$i" file; \
	   done; \
	   rm .git/index && \
	   cd .. && \
	   git clone --bare repo1 && \
	   cd ./repo1.git && git update-server-info && \
	   rm -rf ../repo1 \
	)
	@echo "Created $(PWD)/git-repos/repo1.git with $(N_COMMITS) commits"

# This assumes the other components are running.
clone-repo-static-auth:
	mkdir -p tmp/clone-dir
	(cd tmp/clone-dir && \
	 rm -rf repo1-static-auth && \
	 git clone http://u1:u1@localhost:1234/static-auth/repo1.git repo1-static-auth \
	)

# This assumes the other components are running.
clone-repo-static-no-auth:
	mkdir -p tmp/clone-dir
	(cd tmp/clone-dir && \
	 rm -rf repo1-static-no-auth && \
	 git clone http://localhost:1234/static-no-auth/repo1.git repo1-static-no-auth \
	)

# This assumes the other components are running.
clone-repo-cgi-auth:
	mkdir -p tmp/clone-dir
	(cd tmp/clone-dir && \
	 rm -rf repo1-cgi-auth && \
	 git clone http://u1:u1@localhost:1234/cgi-auth/repo1.git repo1-cgi-auth \
	)

# This assumes the other components are running.
clone-repo-cgi-no-auth:
	mkdir -p tmp/clone-dir
	(cd tmp/clone-dir && \
	 rm -rf repo1-cgi-no-auth && \
	 git clone http://localhost:1234/cgi-no-auth/repo1.git repo1-cgi-no-auth \
	)
