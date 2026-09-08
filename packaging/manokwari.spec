Name:           manokwari
Version:        1.0.0
Release:        0
Summary:        Manokwari desktop panel (Reborn fork, work in progress)
License:        GPL-2.0-only
URL:            https://github.com/cho2/manokwari
Source0:        %{name}-%{version}.tar.xz

BuildRequires:  vala
BuildRequires:  meson
BuildRequires:  ninja
BuildRequires:  gcc
BuildRequires:  intltool
BuildRequires:  gettext-tools
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gio-unix-2.0)
BuildRequires:  pkgconfig(gtk+-3.0)
BuildRequires:  pkgconfig(gdk-3.0)
BuildRequires:  pkgconfig(atk)
BuildRequires:  pkgconfig(gee-0.8)
BuildRequires:  pkgconfig(cairo)
BuildRequires:  pkgconfig(libwnck-3.0)
BuildRequires:  pkgconfig(libnotify)
BuildRequires:  pkgconfig(x11)

# Milestone 3: Manokwari pairs with Openbox (window manager, EWMH-compliant
# for the libwnck-based taskbar) and picom (compositing, needed for the
# clock widget's RGBA transparency) instead of gnome-session + mutter.
# See files/bin/manokwari-session.
Requires:       openbox
Requires:       picom

%description
Manokwari (Reborn) is an independent fork of the BlankOn Manokwari desktop
panel (https://github.com/BlankOn/manokwari), modernized and decoupled
from GNOME-specific dependencies. It pairs with Openbox (window manager)
and picom (compositing) instead of gnome-session/mutter. This is an
early-stage hobby project -- the original WebKit-based frontend has been
replaced with native GTK widgets. See ROADMAP.md upstream for current
status.

%prep
%setup -q

%build
%meson
%meson_build

%install
%meson_install

%files
%license COPYING
%doc README.md ROADMAP.md INVENTORY.md
%{_bindir}/manokwari
%{_bindir}/manokwari-session
%{_datadir}/applications/manokwari.desktop
%{_datadir}/xsessions/manokwari.desktop
%{_sysconfdir}/xdg/menus/manokwari-applications.menu
%{_datadir}/locale/id/LC_MESSAGES/%{name}.mo
%dir %{_datadir}/locale/gay
%dir %{_datadir}/locale/gay/LC_MESSAGES
%{_datadir}/locale/gay/LC_MESSAGES/%{name}.mo
%dir %{_datadir}/locale/jv
%dir %{_datadir}/locale/jv/LC_MESSAGES
%{_datadir}/locale/jv/LC_MESSAGES/%{name}.mo
%dir %{_datadir}/locale/su
%dir %{_datadir}/locale/su/LC_MESSAGES
%{_datadir}/locale/su/LC_MESSAGES/%{name}.mo

%changelog
