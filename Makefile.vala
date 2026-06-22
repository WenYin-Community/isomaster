# Makefile for ISO Master GTK4 (Vala)

PREFIX ?= /usr/local
BINPATH ?= $(PREFIX)/bin
LOCALEDIR ?= $(PREFIX)/share/locale

VERSION = 2.0.0

VALAC = valac
VALA_PKGS = --pkg gtk4 --pkg libadwaita-1 --pkg gio-2.0 --pkg glib-2.0

CC = gcc
GTK_CFLAGS = $(shell pkg-config --cflags gtk4 libadwaita-1)
CFLAGS = -std=gnu99 -Wall -Wno-unused-variable -D_FILE_OFFSET_BITS=64 \
	-DLOCALEDIR=\"$(LOCALEDIR)\" \
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
	$(VALAC) --cc $(CC) $(VALA_PKGS) \
		--vapidir=. --pkg bk --pkg iniparser \
		-C $(VALA_SRC)

$(VALA_OUT): $(VALA_C) $(BK_LIB) $(INIPARSER_LIB)
	$(CC) $(CFLAGS) -o $@ $(VALA_C) $(BK_LIB) $(INIPARSER_LIB) $(GTK_LIBS)

clean:
	$(MAKE) -C bk clean
	rm -f $(VALA_OUT) $(VALA_C) isomaster.h

install: all
	install -d $(DESTDIR)$(BINPATH)
	install $(VALA_OUT) $(DESTDIR)$(BINPATH)

.PHONY: all clean install
