# Building Manokwari (Reborn)

Status (Sept 2026): confirmed working on openSUSE Tumbleweed (built and ran
end to end, Milestones 1-4). Debian 13 (trixie) package names below are
verified against packages.debian.org but not yet build-tested end to end --
that's the next step (Milestone 5).

## openSUSE Tumbleweed

All package names verified via `pkgconfig(...)` provides lookups, not
guessed from naming convention -- openSUSE's devel package names don't
always follow the pattern you'd expect from Debian/Ubuntu/Fedora.

```bash
sudo zypper install vala meson ninja git gcc intltool gettext-tools \
    glib2-devel gtk3-devel at-spi2-core-devel libgee-devel cairo-devel \
    libwnck-devel libnotify-devel libX11-devel openbox picom
```

| pkg-config module (from `meson.build`) | RPM package |
|---|---|
| `glib-2.0`, `gio-unix-2.0` | `glib2-devel` |
| `gtk+-3.0`, `gdk-3.0` | `gtk3-devel` |
| `atk` | `at-spi2-core-devel` (ATK was folded into at-spi2-core upstream -- there is no plain `atk-devel`) |
| `gee-0.8` | `libgee-devel` |
| `cairo` | `cairo-devel` |
| `libwnck-3.0` | `libwnck-devel` (**not** `libwnck-3-devel`) |
| `libnotify` | `libnotify-devel` |
| `x11` | `libX11-devel` |

`openbox` and `picom` are runtime dependencies (Milestone 3 -- Manokwari's
session pairs with Openbox as window manager, picom for compositing), not
build dependencies, but needed to actually run/test the session.

`libgnome-menu-3.0` and `gnome-settings-daemon` were dependencies up through
Milestone 2 but are **no longer needed** as of Milestone 3 -- don't install
`gnome-menus-devel`/`gnome-settings-daemon-devel` unless working on an old
checkout.

To verify any of these yourself if package names shift in a future
Tumbleweed snapshot, don't guess from the library name -- ask zypper
directly:
```bash
zypper search --provides --match-exact "pkgconfig(<module-name>)"
```

## Debian 13 (trixie)

**Not yet build-tested** -- package names below are verified against
packages.debian.org (trixie/stable, Sept 2026) individually, plus
cross-referenced against `gnome-pie`, an unrelated Debian source package
that happens to share almost the same Vala+GTK3+libgee+libwnck dependency
stack, as a sanity check. First actual build attempt is Milestone 5.

```bash
sudo apt install valac meson ninja-build git gcc intltool gettext \
    libglib2.0-dev libgtk-3-dev libatk1.0-dev libgee-0.8-dev libcairo2-dev \
    libwnck-3-dev libnotify-dev libx11-dev openbox picom
```

| pkg-config module (from `meson.build`) | Debian package |
|---|---|
| Vala compiler | `valac` (**not** `vala` -- that's the package name on openSUSE, not Debian) |
| `glib-2.0`, `gio-unix-2.0` | `libglib2.0-dev` |
| `gtk+-3.0`, `gdk-3.0` | `libgtk-3-dev` |
| `atk` | `libatk1.0-dev` |
| `gee-0.8` | `libgee-0.8-dev` |
| `cairo` | `libcairo2-dev` |
| `libwnck-3.0` | `libwnck-3-dev` |
| `libnotify` | `libnotify-dev` |
| `x11` | `libx11-dev` |

`openbox` (3.6.1, trixie stable) and `picom` (12.5-1, trixie stable) both
confirmed present as regular packages, no extra repo needed -- unlike the
brief scare with `build`/`openSUSE:Tools` on the openSUSE side.

Not individually re-verified (standard, near-certain package names,
unlikely to have shifted): `gcc`, `git`, `intltool`, `gettext`.