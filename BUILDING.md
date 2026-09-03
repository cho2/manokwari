# Building Manokwari (Reborn) on openSUSE Tumbleweed

Status: confirmed working (Milestone 1 exit criteria met) on openSUSE Tumbleweed,
Sept 2026. All package names below were verified via `pkgconfig(...)` provides
lookups, not guessed from naming convention -- openSUSE's devel package names
don't always follow the pattern you'd expect from Debian/Ubuntu/Fedora.

## Packages

```bash
sudo zypper install vala meson ninja git gcc intltool gettext-tools \
    glib2-devel gtk3-devel at-spi2-core-devel libgee-devel cairo-devel \
    gnome-menus-devel libwnck-devel libnotify-devel libX11-devel \
    gnome-settings-daemon-devel
```

| pkg-config module (from `meson.build`) | RPM package |
|---|---|
| `glib-2.0`, `gio-unix-2.0` | `glib2-devel` |
| `gtk+-3.0`, `gdk-3.0` | `gtk3-devel` |
| `atk` | `at-spi2-core-devel` (ATK was folded into at-spi2-core upstream -- there is no plain `atk-devel`) |
| `gee-0.8` | `libgee-devel` |
| `cairo` | `cairo-devel` |
| `libgnome-menu-3.0` | `gnome-menus-devel` (**not** `libgnome-menu-3-devel`) |
| `libwnck-3.0` | `libwnck-devel` (**not** `libwnck-3-devel`) |
| `libnotify` | `libnotify-devel` |
| `x11` | `libX11-devel` |
| `gnome-settings-daemon` | `gnome-settings-daemon-devel` (the plain `gnome-settings-daemon` package is the running daemon, not the `.pc` file) |

To verify any of these yourself if package names shift in a future Tumbleweed
snapshot, don't guess from the library name -- ask zypper directly:
```bash
zypper search --provides --match-exact "pkgconfig(<module-name>)"
```

## Build

```bash
git clone https://github.com/cho2/manokwari.git
cd manokwari
git checkout reborn
meson setup build
ninja -C build
```

## Known gotchas

- **Broken/missing `libgio-2.0.so.0` after a fresh Tumbleweed(-WSL) install.**
  If `ninja` fails at the link step with `cannot find -lgio-2.0`, check
  `ls -la /usr/lib64/libgio-2.0.so*` -- if the symlink is red/broken, the
  `libgio-2_0-0` package itself is missing or its install was interrupted
  (seen here as a leftover `/var/cache/gio-2.0/` blocking the unpack). Fix:
  ```bash
  sudo rm -rf /var/cache/gio-2.0
  sudo zypper install --force --force-resolution libgio-2_0-0 glib2-devel
  ```