# CC, AR, RM defined in parent makefile

OBJECTS = bkRead7x.o bkAdd.o bkDelete.o bkExtract.o bkRead.o bkPath.o bkMangle.o bkWrite.o bkWrite7x.o bkTime.o bkSort.o bkError.o bkGet.o bkSet.o bkCache.o bkLink.o bkMisc.o bkIoWrappers.o

# -DDEBUG and -g only used during development
CFLAGS  += -Wall -pedantic -std=gnu99 -Wundef -Wcast-align -W -Wpointer-arith -Wwrite-strings -Wno-unused-parameter

# Additional flags (e.g. sanitizers) that must not replace the warnings above.
# A CFLAGS=... on the make command line would override them entirely, so
# callers such as the ASan CI job append through this variable instead.
CFLAGS  += $(EXTRA_CFLAGS)

# the _FILE_OFFSET_BITS=64 is to enable stat() for large files
CPPFLAGS = -D_FILE_OFFSET_BITS=64

ifdef WINDOWS_BUILD
  CPPFLAGS += -DWINDOWS_BUILD
endif

bk.a: $(OBJECTS)
	@echo 'Creating bk.a'
	@$(AR) -cr bk.a $(OBJECTS)

# static pattern rule
$(OBJECTS): %.o: %.c %.h Makefile bk.h bkInternal.h
	@echo 'Compiling' $<
	@$(CC) $< $(CFLAGS) $(CPPFLAGS) -c -o $@

example: example.c
	$(CC) $(CFLAGS) $(CPPFLAGS) example.c bk.a -o example

clean: 
	$(RM) *.o bk.a

