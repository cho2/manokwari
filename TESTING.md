# Testing Manokwari (Reborn) end-to-end

Assumes a genuinely fresh, minimal distro install (no desktop environment
pre-selected) -- proving Manokwari works as someone's *only* DE, not just
coexisting alongside GNOME/KDE. Both tracks below install just enough
(Xorg, a display manager, Manokwari's own runtime deps) and nothing more.

**A gotcha worth avoiding before you start:** a plain `meson setup build`
with no `--prefix` installs to `/usr/local` when building manually --
different from the RPM build, where openSUSE's `%meson` macro sets
`--prefix=/usr` automatically. If `manokwari-session` ends up in
`/usr/local/bin` instead of `/usr/bin`, a display manager's more
restricted `$PATH` might not find it even though `startx` from your own
shell does. Both tracks below pass `--prefix=/usr` explicitly to sidestep
this.

## 1. openSUSE Tumbleweed

### Base system
```bash
sudo zypper install -t pattern x11
sudo zypper install xinit lightdm lightdm-gtk-greeter
```

### Install Manokwari -- Option A: from OBS (recommended, tests the real package)
```bash
sudo zypper addrepo https://download.opensuse.org/repositories/home:/cho2/openSUSE_Tumbleweed/home:cho2.repo
sudo zypper refresh
sudo zypper install manokwari
```
This alone pulls in `openbox`/`picom` too, since they're declared `Requires:`
in the spec -- nothing else to install manually.

### Install Manokwari -- Option B: from source (if the OBS package isn't published yet)
```bash
sudo zypper install vala meson ninja git gcc intltool gettext-tools \
    glib2-devel gtk3-devel at-spi2-core-devel libgee-devel cairo-devel \
    libwnck-devel libnotify-devel libX11-devel openbox picom
git clone https://github.com/cho2/manokwari.git
cd manokwari
git checkout reborn
meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
```

### Quick sanity check first (fast feedback, skips the display manager)
```bash
echo "exec manokwari-session" > ~/.xinitrc
startx
```
If this alone gets you a working panel, you already know the core build is
fine before touching login-manager configuration at all.

### Full end-to-end via display manager
```bash
sudo systemctl enable lightdm
sudo systemctl set-default graphical.target
sudo reboot
```
At the login screen, pick the **Manokwari** session (the little session-type
icon/menu next to the password field, exact spot depends on the greeter
theme), log in as your user.

## 2. Debian 13 (trixie)

**No build has ever been attempted here** -- treat the first run as higher-risk
than the openSUSE track. Expect at least one surprise (package name, Vala
version strictness, a missing runtime file) -- that's been the pattern every
single time this project has touched a new environment so far. Capture
terminal output if anything fails.

### Base system
```bash
sudo apt update
sudo apt install xserver-xorg xinit lightdm lightdm-gtk-greeter
```

### Install build deps and build from source
No `.deb` package exists yet -- Milestone 5's Debian work so far is a package
*name* audit (see `BUILDING.md`), not a real build attempt.
```bash
sudo apt install valac meson ninja-build git gcc intltool gettext \
    libglib2.0-dev libgtk-3-dev libatk1.0-dev libgee-0.8-dev libcairo2-dev \
    libwnck-3-dev libnotify-dev libx11-dev openbox picom
git clone https://github.com/cho2/manokwari.git
cd manokwari
git checkout reborn
meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
```

### Quick sanity check first
```bash
echo "exec manokwari-session" > ~/.xinitrc
startx
```

### Full end-to-end via display manager
```bash
sudo systemctl enable lightdm
sudo systemctl set-default graphical.target
sudo reboot
```
Pick **Manokwari** at the login screen, same as the openSUSE track.

## 3. Functional checklist (same on both distros)

Run through this once logged in:

- [ ] Taskbar appears, no immediate crash
- [ ] Taskbar clock (`PanelClock`) shows and updates -- day/date/time
- [ ] Click the panel's logo/leftmost button -> native menu opens
- [ ] User header shows real avatar/name/hostname (this is the real
      AccountsService now, not the "unable to connect" fallback seen in
      every sandbox test so far)
- [ ] Type in search -> app list filters live
- [ ] Click an app -> it actually launches, window appears, Openbox
      manages/decorates it, it shows up in the taskbar
- [ ] Places section -> click Home (or any listed folder) -> a file manager
      opens. **Note:** a minimal install likely has no file manager at all --
      install one first if you want this to visibly do something (e.g.
      `pcmanfm`, available on both distros) rather than silently fail on
      `AppInfo.launch_default_for_uri()` finding nothing registered
- [ ] Session buttons visible: Lock, Logout, Restart, and Shutdown only if
      `can_shutdown()` says yes
- [ ] Escape with text in search -> clears search, menu stays open
- [ ] Escape with empty search -> menu closes
- [ ] Print Screen key -> `Utils.print_screen()` fires (still wired to
      `PanelDesktop`'s `key_press_event` even after the bevel/sidebar removal)
- [ ] **Worth specifically observing:** now that the bevel/clock (the one
      thing using RGBA transparency) is gone entirely, does the panel itself
      show any visible transparency/gradient anywhere? The CSS that would've
      styled it (`manokwari.css.in`) turned out to be dead code and got
      removed in Milestone 4 -- so it's genuinely an open question whether
      `picom` is still doing anything *visually* useful right now, versus
      just being a runtime dependency nothing currently exercises. Worth
      noting either way, not something to "fix" during this test.

### Test session buttons carefully
- **Lock**: safe to try, worst case is a stuck lock screen you can't get
  out of (reachable by switching VT or via another user's SSH session) --
  and it's likely to just do nothing anyway, since `Utils.lock_screen()`
  still shells out to `gnome-screensaver-command`, which almost certainly
  isn't installed in this minimal setup. Confirms a known limitation
  rather than a new bug if so.
- **Logout**: should run `openbox --exit`, ending the whole session and
  dropping you back at the LightDM login screen. Safe, reversible -- just
  log back in.
- **Restart / Shutdown**: genuinely restarts/shuts down the machine via
  `org.freedesktop.login1`. Test these last, and only when you're actually
  ready for the machine to restart/power off.

## 4. Reporting back

For each distro, note: which checklist items passed, any new GTK-CRITICAL/
Gdk-CRITICAL beyond the already-tracked `gtk_widget_get_preferred_height`
one (see `ROADMAP.md`), and paste terminal output for anything that outright
failed. Same process we've used throughout this project -- diagnose from
real output, not guesses.