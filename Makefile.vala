# Makefile for ISO Master GTK4 (Vala)

PREFIX ?= /usr/local
BINPATH ?= $(PREFIX)/bin
LOCALEDIR ?= $(PREFIX)/share/locale
ICONPATH ?= $(PREFIX)/share/pixmaps

VERSION = 1.4.0

VALAC = valac
VALA_PKGS = --pkg gtk4 --pkg libadwaita-1 --pkg gio-2.0 --pkg glib-2.0

CC = gcc
GTK_CFLAGS = $(shell pkg-config --cflags gtk4 libadwaita-1)
CFLAGS = -std=gnu99 -Wall -Wno-unused-variable -D_FILE_OFFSET_BITS=64 \
	-DLOCALEDIR=\"$(LOCALEDIR)\" \
	-DICONPATH=\"$(ICONPATH)\" \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"isomaster\" \
	$(GTK_CFLAGS) \
	-I. -Ibk -Iiniparser-4.1/src

BK_LIB = bk/bk.a
INIPARSER_LIB = iniparser-4.1/libiniparser.a
GTK_LIBS = $(shell pkg-config --libs gtk4 libadwaita-1)

VALA_SRC = isomaster.vala
VALA_C = isomaster.c
VALA_OUT = isomaster

all: iconpath.h iconpath.c $(VALA_OUT)

$(BK_LIB):
	$(MAKE) -C bk

$(INIPARSER_LIB):
	$(MAKE) -C iniparser-4.1

iconpath.h:
	@printf 'extern const char *_isomaster_iconpath;\n' > $@

iconpath.c: iconpath.h
	@printf 'const char *_isomaster_iconpath = ICONPATH;\n' > $@

$(VALA_C): $(VALA_SRC) bk.vapi iniparser.vapi iconpath.h
	$(VALAC) --cc $(CC) $(VALA_PKGS) \
		--vapidir=. --pkg bk --pkg iniparser \
		-C $(VALA_SRC)

$(VALA_OUT): $(VALA_C) iconpath.c iconpath.h $(BK_LIB) $(INIPARSER_LIB)
	$(CC) $(CFLAGS) -o $@ $(VALA_C) iconpath.c $(BK_LIB) $(INIPARSER_LIB) $(GTK_LIBS)

clean:
	$(MAKE) -C bk clean
	rm -f $(VALA_OUT) $(VALA_C) isomaster.h iconpath.h iconpath.c

install: all
	install -d $(DESTDIR)$(BINPATH)
	install $(VALA_OUT) $(DESTDIR)$(BINPATH)
	$(MAKE) -C po install DESTDIR=$(DESTDIR) LOCALEDIR=$(LOCALEDIR) RM="rm -f" INSTALL="install"
	$(MAKE) -C icons install DESTDIR=$(DESTDIR) ICONPATH=$(ICONPATH) RM="rm -f" INSTALL="install"

.PHONY: all clean install
