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
- Modern GTK4 + Adwaita user interface

## Screenshots

<p align="center">
  <img src="icons/isomaster.png" alt="ISO Master" width="640">
</p>

## Prerequisites

| Distro | Packages |
|--------|----------|
| Debian / Ubuntu | `build-essential valac libgtk-4-dev libadwaita-1-dev pkg-config gettext` |
| Fedora | `gcc make vala gtk4-devel libadwaita-devel pkgconfig gettext-devel` |
| Arch | `base-devel vala gtk4 libadwaita pkgconf gettext` |
| Slackware | Built-in (no extra packages needed) |

## Building

```bash
make -f Makefile.vala
```

### Build options

| Option | Description |
|--------|-------------|
| `PREFIX=/path` | Installation prefix (default `/usr/local`) |

## Installing

```bash
sudo make -f Makefile.vala install
```

To uninstall:

```bash
sudo make -f Makefile.vala uninstall
```

You can also run `./isomaster` directly from the build directory (icons will not be available unless installed).

## Project Structure

```
isomaster/
├── isomaster.vala      # Main application (Vala/GTK4/Adwaita)
├── isomaster.c         # Generated C code from Vala
├── bk.vapi             # Vala bindings for bk library
├── iniparser.vapi      # Vala bindings for iniparser
├── Makefile.vala       # Build system for Vala version
├── bk/                 # bkisofs library (ISO read/write core, pure C)
│   ├── bkRead.c        #   ISO 9660/Joliet directory reading
│   ├── bkWrite.c       #   ISO image writing
│   ├── bkAdd.c         #   File/directory addition
│   ├── bkDelete.c      #   File/directory deletion
│   ├── bkExtract.c     #   File extraction to local filesystem
│   ├── bkPath.c        #   Internal path operations
│   ├── bkMangle.c      #   ISO 9660 filename mangling
│   ├── bkCache.c       #   Block cache
│   ├── example.c       #   Standalone usage example
│   └── ...
├── iniparser-4.1/      # Bundled INI parser library
├── po/                 # Gettext translation files (8 languages)
└── icons/              # Application icons
```

**Architecture note:** The `bk/` library (`bk.a`) is a self-contained, pure-C ISO manipulation library with no GTK dependency. It can be used independently of the GUI — see `bk/example.c`.

## Supported Languages

- 简体中文 (Chinese Simplified)
- 繁體中文 (Chinese Traditional)
- 日本語 (Japanese)
- 한국어 (Korean)
- Français (French)
- Deutsch (German)
- Español (Spanish)
- Русский (Russian)

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
