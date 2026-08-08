#
# Makefile
#

include ../Makefile.inc

srcfiles	= printenv.ts
extdecls	= 
dstfiles	= $(srcfiles:.ts=.js)
srcdecls	= $(srcfiles:.ts=.d.ts)
dstlib  	= Shell.js
dstdecl		= types/Shell.d.ts

all:	$(dstlib) $(dstdecl)

clean:
	rm -f $(dstfiles) $(dstlib)

$(dstlib): $(dstfiles)
	cat $(dstfiles) > $@

$(dstdecl): dummy
	#cat $(extdecls) > $@
	#(cd types ; cat $(srcdecls)) >> $@
	(cd types ; cat $(srcdecls)) > $@

dummy:

