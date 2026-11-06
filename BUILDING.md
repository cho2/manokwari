# Building Manokwari (Reborn)

## openSUSE Tumbleweed

```bash
sudo zypper install vala meson ninja git gcc intltool gettext-tools \
    glib2-devel gtk3-devel at-spi2-core-devel libgee-devel cairo-devel \
    libwnck-devel libnotify-devel libX11-devel openbox picom \
    light-locker nitrogen obconf lxappearance-obconf
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

To verify any of these yourself if package names shift in a future
Tumbleweed snapshot, don't guess from the library name -- ask zypper
directly:
```bash
zypper search --provides --match-exact "pkgconfig(<module-name>)"
```

## Debian 13 (trixie)

```bash
sudo apt install valac meson ninja-build git gcc intltool gettext \
    libglib2.0-dev libgtk-3-dev libatk1.0-dev libgee-0.8-dev libcairo2-dev \
    libwnck-3-dev libnotify-dev libx11-dev openbox picom \
    light-locker nitrogen obconf lxappearance-obconf
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

