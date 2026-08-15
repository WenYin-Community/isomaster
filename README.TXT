ISO Master
==========

http://littlesvr.ca/isomaster/

ISO Master is an open-source, easy to use, graphical CD image editor for
Linux and BSD. Basically you can use this program to extract files from an
ISO, add files to an ISO, and create bootable ISOs - all in a graphical
user interface. It can open ISO, NRG, and some MDF files but can only save
as ISO.

ISO Master is based on bkisofs - a library for reading, modifying and
writing ISO images. The GUI is written in Vala with GTK4 and libadwaita.

Features
--------

- Open and browse ISO 9660 images (also supports NRG and some MDF files)
- Add files and directories to an image
- Extract files and directories from an image
- Delete files and directories from an image
- Create bootable ISO images
- Edit files in-place using an external editor (changes are written back
  into the image)
- Add/extract files by drag-and-drop between the file browser and the ISO
  browser
- Long operations run in the background with a live progress bar
- Save as ISO format
- Full internationalization support (gettext)

Prerequisites for Compiling from Source
---------------------------------------

You need gcc, make, valac, pkg-config, GTK4 development files, libadwaita
development files, the iniparser development files and gettext.
On Debian/Ubuntu: build-essential valac libgtk-4-dev libadwaita-1-dev
libiniparser-dev pkg-config gettext
On Fedora: gcc make vala gtk4-devel libadwaita-devel iniparser-devel
pkgconfig gettext-devel

Compiling and Installing from Source
------------------------------------

To compile, simply type

make -f Makefile.vala

at the command prompt in the directory where you extracted the archive.

And to install (this is optional, you can run from the directory where you
compiled it, though you won't get icons if you don't install):

sudo make -f Makefile.vala install

If you get errors, or even warnings, please do send me the output so I can
fix them.

Uninstalling from Source
------------------------

If you followed the steps above to install ISO Master, use the following
to uninstall it:

sudo make -f Makefile.vala uninstall

Running the Tests
-----------------

The bkisofs library has a unit test suite:

cd tests && ./run_tests.sh

Contact
-------

I would love to hear from you, to know how you made use of either ISO
Master or bkisofs, or with bug reports, or feature requests. Please use
the form at http://littlesvr.ca/misc/contactandrew.php to send me email.
Thanks in advance!

Bug Reports
-----------

Please help me improve ISO Master by sending me bug reports. The more of
the following you can do, the easier it will be for me to fix:
- be able to reproduce the bug consistently
- run ISO Master from a terminal window and send me the output (if any)
  that is printed there
- if it only happens with one image file, tell me what it is and, if it's
  freely available, where i can get it
- it's better to give me too much detail then too little

Credits
-------

See CREDITS.TXT or Help/About/Credits for a list of contributors to ISO
Master.

License
-------

The source code for this version of ISO Master and bkisofs is distributed
under the GNU General Public Licence version 2. See LICENCE for full text.
