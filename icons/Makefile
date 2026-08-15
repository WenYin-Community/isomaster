# ICONPATH, DATADIR, RM, INSTALL defined in parent makefile

ICONS = isomaster.png go-back-kearone.png folder-new-kearone.png add2-kearone.png extract2-kearone.png delete-kearone.png

# Install the app icon into the hicolor theme as well, so desktop
# entries can use Icon=isomaster (name-based lookup) instead of an
# absolute path that breaks with custom PREFIX values.
HICOLOR_DIR = $(DATADIR)/icons/hicolor/64x64/apps

install: 
	$(INSTALL) -d $(DESTDIR)$(ICONPATH)
	for NAME in $(ICONS); do \
	  $(INSTALL) -v -m 644 $$NAME $(DESTDIR)$(ICONPATH); \
	done
	$(INSTALL) -d $(DESTDIR)$(HICOLOR_DIR)
	$(INSTALL) -v -m 644 isomaster.png $(DESTDIR)$(HICOLOR_DIR)/isomaster.png

uninstall:
	for NAME in $(ICONS); do \
	  $(RM) -f $(DESTDIR)$(ICONPATH)/$$NAME; \
	done
	$(RM) -f $(DESTDIR)$(HICOLOR_DIR)/isomaster.png
