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
	-Ibk -Iiniparser-4.1/src

BK_LIB = bk/bk.a
INIPARSER_LIB = iniparser-4.1/libiniparser.a
GTK_LIBS = $(shell pkg-config --libs gtk4 libadwaita-1)

VALA_SRC = isomaster.vala
VALA_C = isomaster.c
VALA_OUT = isomaster

all: $(VALA_OUT)

$(BK_LIB):
	$(MAKE) -C bk

$(INIPARSER_LIB):
	$(MAKE) -C iniparser-4.1

$(VALA_C): $(VALA_SRC) bk.vapi iniparser.vapi
	@sed 's|ICONS_PATH_PLACEHOLDER|$(ICONPATH)|g' $(VALA_SRC) > isomaster_build.vala
	$(VALAC) --cc $(CC) $(VALA_PKGS) \
		--vapidir=. --pkg bk --pkg iniparser \
		-C isomaster_build.vala
	mv isomaster_build.c $(VALA_C)
	@rm -f isomaster_build.vala

$(VALA_OUT): $(VALA_C) $(BK_LIB) $(INIPARSER_LIB)
	$(CC) $(CFLAGS) -o $@ $(VALA_C) $(BK_LIB) $(INIPARSER_LIB) $(GTK_LIBS)

clean:
	$(MAKE) -C bk clean
	rm -f $(VALA_OUT) $(VALA_C) isomaster.h

install: all
	install -d $(DESTDIR)$(BINPATH)
	install $(VALA_OUT) $(DESTDIR)$(BINPATH)
	$(MAKE) -C po install DESTDIR=$(DESTDIR) LOCALEDIR=$(LOCALEDIR) RM="rm -f" INSTALL="install"
	$(MAKE) -C icons install DESTDIR=$(DESTDIR) ICONPATH=$(ICONPATH) RM="rm -f" INSTALL="install"

.PHONY: all clean install
