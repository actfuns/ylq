## Process this file with automake to produce Makefile.in

SUBDIRS		= src doc
CLEANFILES	= *~ .*~
EXTRA_DIST	= acconfig.h @PACKAGE@.spec @PACKAGE@-config.in

doc_DATA	= AUTHORS COPYING NEWS TODO THANKS
docdir		= $(datadir)/doc/@PACKAGE@

bin_SCRIPTS	= @PACKAGE@-config

SIG_CMD		= gpg -b
RPM_DIR		= /usr/src/rpm/RPMS/i586

pkg:	sig

sig:	distcheck
	$(SIG_CMD) @PACKAGE@-@VERSION@.tar.gz

rpm:	distcheck
	sudo rpmbuild -tb --clean @PACKAGE@-@VERSION@.tar.gz
	cp $(RPM_DIR)/@PACKAGE@-@VERSION@-0.i586.rpm .
	$(SIG_CMD) @PACKAGE@-@VERSION@-0.i586.rpm

.PHONY: doc