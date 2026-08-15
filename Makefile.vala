# Makefile for ISO Master GTK4 (Vala)

PREFIX ?= /usr/local
BINPATH ?= $(PREFIX)/bin
LOCALEDIR ?= $(PREFIX)/share/locale
ICONPATH ?= $(PREFIX)/share/pixmaps

VERSION = 1.6.0

VALAC = valac
VALA_PKGS = --pkg gtk4 --pkg libadwaita-1 --pkg gio-2.0 --pkg glib-2.0

CC = gcc
GTK_CFLAGS = $(shell pkg-config --cflags gtk4 libadwaita-1)
# Fall back to the standard layout if pkg-config cannot find iniparser
# (e.g. inside rpmbuild on some distros)
INIPARSER_CFLAGS = $(shell pkg-config --cflags iniparser 2>/dev/null || echo "-I/usr/include/iniparser")
INIPARSER_LIBS = $(shell pkg-config --libs iniparser 2>/dev/null || echo "-liniparser")
CFLAGS = -std=gnu99 -Wall -Wno-unused-variable -D_FILE_OFFSET_BITS=64 \
	-DLOCALEDIR=\"$(LOCALEDIR)\" \
	-DICONPATH=\"$(ICONPATH)\" \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"isomaster\" \
	$(GTK_CFLAGS) \
	$(INIPARSER_CFLAGS) \
	-I. -Ibk

BK_LIB = bk/bk.a
GTK_LIBS = $(shell pkg-config --libs gtk4 libadwaita-1)

VALA_SRC = isomaster.vala settings.vala file-item.vala iso-operations.vala util.vala
VALA_C = isomaster.c
# valac generates one C file per source file
VALA_C_FILES = $(VALA_SRC:.vala=.c)
VALA_OUT = isomaster

all: iconpath.h iconpath.c $(VALA_OUT)

$(BK_LIB):
	$(MAKE) -C bk

iconpath.h:
	@printf 'extern const char *_isomaster_iconpath;\n' > $@
	@printf 'extern const char *_isomaster_version;\n' >> $@

iconpath.c: iconpath.h version.inc
	@printf 'const char *_isomaster_iconpath = ICONPATH;\n' > $@
	@printf 'const char *_isomaster_version = VERSION;\n' >> $@

# Stamp carrying the version number: changing VERSION in this makefile
# updates the stamp, which in turn forces valac/gcc to rebuild so the
# new version actually reaches the binary.
version.inc: Makefile.vala
	@printf '%s' '$(VERSION)' > $@

$(VALA_C): $(VALA_SRC) bk.vapi iniparser.vapi iconpath.h version.inc
	$(VALAC) --cc $(CC) $(VALA_PKGS) \
		--vapidir=. --pkg bk --pkg iniparser \
		-C $(VALA_SRC)

$(VALA_OUT): $(VALA_C_FILES) iconpath.c iconpath.h version.inc $(BK_LIB)
	$(CC) $(CFLAGS) -o $@ $(VALA_C_FILES) iconpath.c $(BK_LIB) $(INIPARSER_LIBS) $(GTK_LIBS)

clean:
	$(MAKE) -C bk clean
	rm -f $(VALA_OUT) $(VALA_C_FILES) isomaster.h iconpath.h iconpath.c version.inc

# Installation prefix layout
DATADIR ?= $(PREFIX)/share
DESKTOPDIR ?= $(DATADIR)/applications
MANDIR ?= $(DATADIR)/man/man1

install: all
	install -d $(DESTDIR)$(BINPATH)
	install $(VALA_OUT) $(DESTDIR)$(BINPATH)
	install -d $(DESTDIR)$(DESKTOPDIR)
	install -m 644 isomaster.desktop $(DESTDIR)$(DESKTOPDIR)/
	install -d $(DESTDIR)$(MANDIR)
	install -m 644 isomaster.1 $(DESTDIR)$(MANDIR)/
	$(MAKE) -C po install DESTDIR=$(DESTDIR) LOCALEDIR=$(LOCALEDIR) RM="rm -f" INSTALL="install"
	$(MAKE) -C icons install DESTDIR=$(DESTDIR) ICONPATH=$(ICONPATH) DATADIR=$(DATADIR) RM="rm -f" INSTALL="install"

uninstall:
	rm -f $(DESTDIR)$(BINPATH)/$(VALA_OUT)
	rm -f $(DESTDIR)$(DESKTOPDIR)/isomaster.desktop
	rm -f $(DESTDIR)$(MANDIR)/isomaster.1
	$(MAKE) -C po uninstall DESTDIR=$(DESTDIR) LOCALEDIR=$(LOCALEDIR) RM="rm -f"
	$(MAKE) -C icons uninstall DESTDIR=$(DESTDIR) ICONPATH=$(ICONPATH) DATADIR=$(DATADIR) RM="rm -f"

.PHONY: all clean install uninstall
