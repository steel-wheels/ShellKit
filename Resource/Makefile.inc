#
# Makefile
#

tsc	= npx tsc
tsc_opt	= -t ES2024 --lib "es2024" --declaration --declarationDir types \
	  --typeRoots types \
	  --alwaysStrict --strict --strictNullChecks --pretty

%.js: %.ts
	$(tsc) $(tsc_opt) $<

