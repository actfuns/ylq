## Process this file with automake to produce Makefile.in

SUBDIRS = man3 html latex

doc:
	@if [ -f latex/Makefile ]; then mv latex/Makefile latex/Makefile.dox; fi
	doxygen
	make -C latex refman.dvi refman.ps refman.pdf
	@mv latex/Makefile.dox latex/Makefile
