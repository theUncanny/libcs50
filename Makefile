VERSION := 8.0.3

# installation directory (/usr/local by default)
DESTDIR ?= /usr/local

.PHONY: build
build: clean
	$(CC) -c -fPIC -std=gnu99 -Wall -o cs50.o src/cs50.c
	$(CC) -shared -o libcs50.so cs50.o
	rm -f cs50.o
	install -D -m 644 src/cs50.h build/include/cs50.h
	mkdir -p build/lib build/src/libcs50
	mv libcs50.so build/lib
	cp -r src/* build/src/libcs50

.PHONY: install
install: build docs
	mkdir -p $(DESTDIR) $(DESTDIR)/share/man/man3
	cp -r build/* $(DESTDIR)
	cp -r debian/docs/* $(DESTDIR)/share/man/man3

.PHONY: clean
clean:
	rm -rf build *.deb

# requires asciidoctor (gem install asciidoctor)
.PHONY: docs
docs:
	asciidoctor -d manpage -b manpage -D build/docs/ docs/*.adoc

.PHONY: deb
deb: build docs
	mkdir -p build/usr build/usr/share/man/man3
	cp -r build/include build/lib build/src build/usr
	cp -r build/docs/* build/usr/share/man/man3
	mkdir -p build/usr
	fpm \
	--name libcs50 \
	--version "$(VERSION)" \
	--conflicts "libcs50 (<< $(VERSION))" \
	--conflicts lib50-c \
    --conflicts library50-c \
	--provides libcs50 \
	--provides lib50-c \
	--provides library50-c \
	--replaces "libcs50 (<= $(VERSION))" \
	--replaces lib50-c \
	--replaces library50-c \
	--maintainer "CS50 <sysadmins@cs50.harvard.edu>" \
	--after-install postinst \
	--after-remove postrm \
	--chdir build \
	--input-type dir \
	--output-type deb \
	--deb-no-default-config-files \
	--depends c-compiler \
	--description "CS50 library for C" \
	--url "" \
	usr

.PHONY: rpm
rpm: build docs
	mkdir -p build/usr build/usr/share/man/man3
	cp -r build/include build/lib build/src build/usr
	cp -r build/docs/* build/usr/share/man/man3
	mkdir -p build/usr
	fpm \
	-C build \
	-m "CS50 <sysadmins@cs50.harvard.edu>" \
	-n libcs50 \
	-s dir \
	-t rpm \
	-v "$(VERSION)" \
	--description "CS50 library for C" \
	usr

# used by .travis.yml
.PHONY: packages
packages: deb rpm

.PHONY: hack
hack:
	rm -rf build/hack && mkdir -p build/hack
	cat src/cs50.h > build/hack/cs50.h
	echo "\n#ifndef _CS50_C\n#define _CS50_C\n" >> build/hack/cs50.h
	cat src/cs50.c >> build/hack/cs50.h
	echo "\n#endif" >> build/hack/cs50.h

# used by .travis.yml
.PHONY: version
version:
	@echo $(VERSION)
