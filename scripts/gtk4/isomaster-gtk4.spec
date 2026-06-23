Name:		isomaster-gtk4
Summary:	An easy to use GUI CD image editor (GTK4 version)
Version:	1.4.0
Release:	1%{?dist}
License:	GPL-2.0-only
URL:		http://littlesvr.ca/isomaster/
Source0:	isomaster-gtk4-%{version}.tar.bz2
%define debug_package %{nil}
Requires:	xdg-utils
BuildRequires:	gcc
BuildRequires:	make
BuildRequires:	vala
BuildRequires:	gtk4-devel
BuildRequires:	libadwaita-devel
BuildRequires:	gettext
BuildRequires:	pkg-config

%description
ISO Master: an easy to use graphical CD image editor (GTK4 version).
It allows to extract files from an ISO, add files to an ISO,
and create bootable ISOs - all in a graphical user interface.
It can open ISO, NRG, and some MDF files but can only save as ISO.

This version is built with GTK4 and libadwaita for a modern look and feel.

%prep
%setup -q

%build
make -f Makefile.vala PREFIX=%{_prefix} VERSION=%{version}

%install
rm -fr %{buildroot}
make -f Makefile.vala install DESTDIR=%{buildroot} PREFIX=%{_prefix} VERSION=%{version}

# Rename binary to isomaster-gtk4 to avoid conflict with GTK2 version
mv %{buildroot}%{_bindir}/isomaster %{buildroot}%{_bindir}/isomaster-gtk4

# Rename translation files to avoid conflict with isomaster package
for mo in %{buildroot}%{_datadir}/locale/*/LC_MESSAGES/isomaster.mo; do
    mv "$mo" "$(dirname $mo)/isomaster-gtk4.mo"
done

# Create GTK4 desktop file
install -d %{buildroot}%{_datadir}/applications
cat > %{buildroot}%{_datadir}/applications/isomaster-gtk4.desktop << EOF
[Desktop Entry]
Name=ISO Master (GTK4)
GenericName=ISO File Editor
GenericName[ca]=Editor de fitxers ISO
GenericName[es]=Editor de ficheros ISO
GenericName[ru]=Редактор файлов ISO
Comment=Read, write and modify ISO images
Comment[ca]=Llegiu, escriviu i modifiqueu imatges ISO
Comment[es]=Leer, escribir i modificar imagenes ISO
Comment[ru]=Чтение, запись и изменение образов ISO
Exec=isomaster-gtk4
Terminal=false
StartupNotify=true
Type=Application
Categories=AudioVideo;DiscBurning;
MimeType=application/x-iso;
Icon=isomaster
EOF

# Install man page (rename to avoid conflict)
install -d %{buildroot}%{_mandir}/man1
install -m 644 isomaster.1 %{buildroot}%{_mandir}/man1/isomaster-gtk4.1

%find_lang isomaster-gtk4

%files -f isomaster-gtk4.lang
%doc CHANGELOG.TXT CREDITS.TXT LICENCE README.TXT TODO.TXT
%attr(0755,root,root) %{_bindir}/isomaster-gtk4
%{_datadir}/applications/isomaster-gtk4.desktop
%{_datadir}/pixmaps/isomaster.png
%{_datadir}/pixmaps/add2-kearone.png
%{_datadir}/pixmaps/delete-kearone.png
%{_datadir}/pixmaps/extract2-kearone.png
%{_datadir}/pixmaps/folder-new-kearone.png
%{_datadir}/pixmaps/go-back-kearone.png
%{_mandir}/man1/isomaster-gtk4.1*

%changelog
* Mon Jun 23 2025 ISO Master Team <info@littlesvr.ca> - 1.4.0-1
- Initial GTK4 release with libadwaita support
- Modern UI with GTK4 and libadwaita
- Built with Vala language
