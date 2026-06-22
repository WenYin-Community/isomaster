[中文](README.zh-CN.md) | English

# ISO Master

An easy-to-use, open-source graphical CD image editor for Linux and BSD.

## Features

- Open and browse ISO 9660 images (also supports NRG and some MDF files)
- Add files and directories to an image
- Extract files and directories from an image
- Delete files and directories from an image
- Create bootable ISO images
- Edit files in-place using an external editor
- Save as ISO format
- Full internationalization support (gettext)

## Screenshots

<p align="center">
  <img src="icons/isomaster.png" alt="ISO Master" width="640">
</p>

## Prerequisites

| Distro | Packages |
|--------|----------|
| Debian / Ubuntu | `build-essential libgtk2.0-dev pkg-config gettext` |
| Fedora | `gcc make gtk2-devel pkgconfig gettext-devel` |
| Arch | `base-devel gtk2 pkgconf gettext` |
| Slackware | Built-in (no extra packages needed) |

## Building

```bash
make
```

### Build options

| Option | Description |
|--------|-------------|
| `USE_SYSTEM_INIPARSER=1` | Link against system libiniparser instead of bundled `iniparser-4.1/` |
| `WITHOUT_NLS=1` | Disable internationalization |
| `PREFIX=/path` | Installation prefix (default `/usr/local`) |
| `DEFAULT_EDITOR=prog` | Default file editor (default `leafpad`) |
| `DEFAULT_VIEWER=prog` | Default file viewer (default `firefox`) |

## Installing

```bash
sudo make install
```

To uninstall:

```bash
sudo make uninstall
```

You can also run `./isomaster` directly from the build directory (icons will not be available unless installed).

## Project Structure

```
isomaster/
├── isomaster.c        # Entry point
├── window.c           # Main window, menu bar, toolbar
├── browser.c          # Common file browser logic
├── fsbrowser.c        # Local filesystem browser (left pane)
├── isobrowser.c       # ISO image browser (right pane)
├── settings.c         # Preferences (via iniparser)
├── boot.c             # Boot image settings dialog
├── editfile.c         # In-place file editing via external editor
├── about.c / error.c  # About dialog, error message translation
├── bk/                # bkisofs library (ISO read/write core, pure C)
│   ├── bkRead.c       #   ISO 9660/Joliet directory reading
│   ├── bkWrite.c      #   ISO image writing
│   ├── bkAdd.c        #   File/directory addition
│   ├── bkDelete.c     #   File/directory deletion
│   ├── bkExtract.c    #   File extraction to local filesystem
│   ├── bkPath.c       #   Internal path operations
│   ├── bkMangle.c     #   ISO 9660 filename mangling
│   ├── bkCache.c      #   Block cache
│   ├── example.c      #   Standalone usage example
│   └── ...
├── iniparser-4.1/     # Bundled INI parser library
├── po/                # Gettext translation files
└── icons/             # Application icons
```

**Architecture note:** The `bk/` library (`bk.a`) is a self-contained, pure-C ISO manipulation library with no GTK dependency. It can be used independently of the GUI — see `bk/example.c`.

## Contributing

Bug reports and patches are welcome. Please provide:

- Steps to reproduce the issue
- Terminal output (if any)
- The image file that triggers the bug (if freely available)

## License

GNU General Public License v2. See [LICENCE.TXT](LICENCE.TXT).

## Links

- Homepage: http://littlesvr.ca/isomaster/
- Contact: http://littlesvr.ca/contact.php
