# Roadmap — Manokwari (Reborn)

Fork independen dari [BlankOn/manokwari](https://github.com/BlankOn/manokwari), tidak
berafiliasi dengan proyek/distro BlankOn. Proyek pribadi/hobi oleh
[@cho2](https://github.com/cho2). Kerja aktif ada di branch **`reborn`**, bukan `master`.

Dokumen ini dimutakhirkan seiring progres — checklist yang sudah selesai dicoret,
bukan dihapus, supaya keputusan lama tetap terlihat alasannya.

## Keputusan Arsitektur (terkunci, jangan diubah tanpa alasan kuat)

- **Application ID:** `io.github.cho2.Manokwari`
- **Display server: X11 saja.** Wayland sengaja di luar scope untuk sekarang — lihat
  diskusi pros/cons di riwayat proyek; bisa direvisit kalau ekosistem compositor
  wlroots makin matang dan proyek masih aktif.
- **Lepas dari GNOME:** ganti dependensi yang GNOME-lock dengan implementasi generik/
  freedesktop-standard (UPower, systemd-logind, GDesktopAppInfo, dst) — bukan sekadar
  port dependensi versi baru.
- **Window manager: Openbox, compositor: picom.** Menggantikan gnome-session+mutter
  sepenuhnya (Milestone 3). Dipilih dari 3 kandidat (Marco, Xfwm4, Openbox) — lihat
  riwayat diskusi untuk perbandingan pros/cons lengkap. Xfwm4 sebagai cadangan kalau
  kombinasi ini ada kendala tak terduga.
- **Frontend: native GTK3, bukan WebKit.** Opsi B dari 2 opsi WebKit yang dipertimbangkan
  (A: port ke webkit2gtk-4.1, B: rewrite native). Alasan utama: footprint & beban
  maintenance patch keamanan WebKit tidak sepadan untuk hobby project solo.
- **Target OBS: openSUSE Tumbleweed dulu, satu-satunya prioritas saat ini.**
  openSUSE Leap, Debian, dan Fedora **sengaja ditunda**, bukan dibatalkan.
  Alasan Leap ditunda: Leap 16.0 (versi aktif saat ini — Leap 15.6 sudah EOL
  30 April 2026) ternyata tidak punya paket resmi `vala` maupun `gtk3`, dan tidak
  ada repo backports/legacy untuk Leap 16 yang bisa menambal itu.

## Status Milestone

### ✅ Milestone 0 — Housekeeping & Identitas (Selesai)
- [x] README + MAINTAINERS: deklarasi fork independen, kredit penuh ke BlankOn
- [x] Application ID diganti di kode (`main.vala`)
- [x] `INVENTORY.md` — audit lengkap semua titik coupling ke GNOME (file + baris),
      jadi peta jalan konkret untuk Milestone 3

### ✅ Milestone 1 — Compile Baseline (Selesai)
- [x] `meson.build`: `gee-1.0` → `gee-0.8` (port penuh, bukan stub), dependency
      `unique-3.0` dan `webkitgtk-3.0` dihapus dari build (keduanya sudah tidak ada
      paketnya di distro manapun)
- [x] **Temuan:** pemakaian JSCore ternyata jauh lebih luas dari dugaan awal — bukan
      cuma 2 file `*-html.vala`, tapi 6 file lain (`utils.vala`, `panel-user.vala`,
      `panel-desktop-data.vala`, `xdg-data.vala`, `panel-places.vala`,
      `panel-session-manager.vala`). Semua sudah di-guard dengan marker
      `STUB (Milestone 1)`, logic non-JS di file yang sama dibiarkan utuh.
- [x] `panel-html-stubs.vala` (baru): placeholder `Gtk.Label` untuk `PanelMenuHTML`/
      `PanelDesktopHTML` supaya UI lain tetap compile & link
- [x] Fix kompatibilitas Vala modern: 3 error generic-ownership `Gee.HashMap` di
      `panel-window.vala` (Vala 0.56 lebih strict dari compiler saat kode ini ditulis)
- [x] Diverifikasi **build hijau di dua toolchain**: Ubuntu 24.04 (proxy awal) dan
      openSUSE Tumbleweed
- [x] `BUILDING.md` — daftar paket zypper terverifikasi (lewat `pkgconfig(...)`
      lookup, bukan tebakan nama paket) + troubleshooting (paket devel yang beda
      konvensi penamaan, `libgio-2.0.so.0` yang sempat corrupt di openSUSE Tumbleweed)
- Dikirim sebagai 4 commit terpisah (lihat riwayat git branch `reborn`):
  `build: bump gee to 0.8, drop dead unique-3.0/webkitgtk-3.0 deps` ·
  `refactor(main): guard out Unique.App single-instance check` ·
  `refactor: guard out WebKit/JSCore bridge, add native placeholder views` ·
  `fix(panel-window): resolve Gee.HashMap generic ownership errors`

### ✅ Milestone 2 — Setup OBS & Loop Packaging (Selesai)
*(scope: openSUSE Tumbleweed saja dulu — bukan multi-distro sekaligus)*
- [x] Home project `home:cho2`, package `manokwari` dibuat via `osc mkpac`
- [x] `manokwari.spec` — `BuildRequires` pakai pola `pkgconfig(<module>)`, bukan nama
      paket RPM literal, supaya tidak rapuh terhadap perbedaan penamaan antar
      snapshot/distro (pelajaran dari drama nama paket di Milestone 1)
- [x] Fix "directories not owned by a package" — `%dir` eksplisit untuk
      `/usr/share/gnome-session/sessions` dan 3 direktori locale daerah
      (`gay`, `jv`, `su`) yang tidak ter-cover paket dasar sistem
- [x] Tarball sumber dibuat manual dulu (`git archive`) untuk percobaan pertama,
      bukan langsung pakai `_service`/`tar_scm` otomatis — mengurangi jumlah
      mekanisme baru yang belum teruji sekaligus
- [x] **Build sukses di server OBS**: `openSUSE_Tumbleweed x86_64: succeeded`
      (arch `i586` sengaja tidak diaktifkan — tidak relevan untuk target ini)
- **Status `_service` (tar_scm otomatis):** file-nya sudah pernah dirancang (draft),
  tapi **belum pernah dipakai atau diuji sama sekali** — build yang berhasil di atas
  pakai tarball manual (`git archive`), bukan `_service` ini. Belum di-`osc add`,
  belum masuk checkout OBS, belum masuk git repo. Kalau nanti mau otomasi
  "auto-fetch dari GitHub" (ganti tarball manual → `tar_scm`), ini titik mulainya —
  tapi anggap sebagai pekerjaan baru dari nol, bukan sesuatu yang tinggal
  diaktifkan begitu saja.

### ✅ Milestone 3 — Lepas Dependensi GNOME-Lock (Selesai)
Semua item selesai. Tidak ada satu pun paket berlabel GNOME tersisa di dependency Manokwari.

- [x] ~~`gee-1.0` → `gee-0.8`~~ — selesai di Milestone 1
- [x] `unique-3.0` → `GLib.Application` — `register()`/`get_is_remote()` lewat D-Bus,
      app id sama (`io.github.cho2.Manokwari`)
- [x] `gnome-settings-daemon` (brightness) → `org.freedesktop.login1.Session.SetBrightness`
      + baca nilai langsung dari `/sys/class/backlight` (logind sengaja cuma sediakan
      setter, pola sama seperti `brightnessctl`)
- [x] `libgnome-menu-3.0` → `GLib.AppInfo`/`GLib.DesktopAppInfo` — tuntas sebagai bagian
      dari rewrite menu native (lihat WebKit di bawah), bukan dikerjakan terpisah
- [x] `libwnck-3.0` — dipertahankan sesuai keputusan pragmatis awal, tidak disentuh
- [x] **WebKit/JSCore → native GTK penuh (Opsi B)**, dua fase:
  - Fase 1 (menu): `menu.html` → `src/panel-menu-native.vala`. Header user
    (`PanelUser`, sudah live sejak Milestone 1), search + app list
    (`GLib.AppInfo`), Places (Home/folder XDG/mount via `VolumeMonitor`),
    4 tombol sesi disambung langsung ke `PanelSessionManager` yang backend-nya
    ternyata sudah hidup sejak awal (cuma dulu dipanggil dari JS)
  - Fase 2 (desktop): `desktop.html` → `src/panel-desktop-native.vala`, cuma jam
    (posisi kanan-bawah, format sama, locale-aware ke sistem — bukan hardcode
    Indonesia). Semua yang lain (bookmark BlankOn, music player, widget cuaca
    "Tekukur", grid 14 ikon settings) **didrop**, bukan ditunda
  - Bonus: folder `system/` (jQuery, moment.js, aset widget cuaca) dikeluarkan
    dari install — sudah 100% dead weight begitu kedua konsumen HTML diganti native
- [x] **Session manager + requirement `mutter`** → diganti **Openbox + picom**
      (lihat perbandingan kandidat WM di riwayat diskusi — Openbox dipilih karena
      paket sudah tersedia di Tumbleweed, filosofi minimalis paling sesuai,
      preseden kuat di LXQt; picom untuk compositing yang dibutuhkan widget jam)
  - `files/sessions/` dihapus total, `files/bin/blankon-session` →
    `manokwari-session` (`picom & manokwari & exec openbox`),
    `files/xsessions/blankon.desktop` → `manokwari.desktop`
    (`DesktopNames` GNOME dibuang, teks BlankOn dibersihkan — ini yang
    ditunda dari Milestone 0)
  - `panel-session-manager.vala`: `org.gnome.SessionManager` → `org.freedesktop.login1`
    (reboot/shutdown/can_shutdown) + `openbox --exit` (logout, tidak ada
    padanan logind untuk konsep "logout sesi GUI")
  - `PanelShell` (penyamaran jadi `org.gnome.Shell`) dihapus; `PanelEndSessionDialog`
    disimpan tidak terpakai — kandidat bagus untuk dialog konfirmasi lokal
    sebelum logout/shutdown, belum disambung (lihat "Belum dikerjakan" di bawah)

**Bonus fix di luar scope asli, ditemukan lewat testing end-to-end:**
- `Utils.ungrab()` di `utils.vala` — null-device guard yang hilang (padahal
  `grab()` pasangannya sudah punya), menyebabkan 3 `Gdk-CRITICAL` tiap menu
  ditutup. Dikonfirmasi bug pre-existing lewat testing nyata di Tumbleweed,
  bukan cuma sandbox — root cause ketemu, ditambal.

**Known issue, sengaja tidak dikejar:** `Gtk-CRITICAL: gtk_widget_get_preferred_height`
muncul konsisten di 3 kali run terpisah (sandbox, mesin nyata, run ulang) —
polanya menunjuk ke area `PanelWindowHost`/Tray, bukan kode Fase 1/2 kita, tapi
belum dibuktikan 100%. Non-fatal, tidak menghalangi apa pun. Selidiki lagi kalau
mulai mengganggu.

**Belum dikerjakan (bukan bug, follow-up kecil opsional):** sambungkan ulang
`PanelEndSessionDialog` sebagai dialog konfirmasi ("yakin mau logout/shutdown?")
sebelum tombol sesi di menu native benar-benar eksekusi aksinya.

### ⏳ Milestone 4 — Finalisasi Identitas & Branding (Sebagian sudah selesai sebagai efek samping Milestone 3)
- [x] ~~Rename D-Bus service name (`org.gnome.Panel` claim)~~ — dihapus total (bukan
      di-rename, memang sudah tidak relevan tanpa gnome-session)
- [x] ~~Rename `blankon.desktop` → `manokwari.desktop`, `blankon-session` →
      `manokwari-session`~~ — selesai sebagai bagian dari rework session manager
- [ ] GSettings schema ID — tidak ada schema milik sendiri untuk di-rename (Manokwari
      cuma baca schema eksternal `org.gnome.system.locale`/`org.gnome.desktop.background`,
      prioritas rendah, lihat `INVENTORY.md` bagian 4)
- [ ] Ikon/splash
- [ ] Keputusan kategori menu `Geo.BlankOn` di `manokwari-applications.menu`
      (branded BlankOn, konten bukan teknis — perlu keputusan terpisah)

### ⏳ Milestone 5 — Uji Lintas-Distro & Stabilisasi (Belum mulai)
- [ ] Perluas target OBS: openSUSE Leap (setelah solusi vala/gtk3-nya jelas),
      Debian, Fedora — sesuai urutan prioritas rendah yang disepakati

### ⏳ Milestone 6 — Rilis & Maintenance (Belum mulai)

## Referensi
- `INVENTORY.md` — audit lengkap dependensi GNOME (file + baris)
- `BUILDING.md` — cara build di openSUSE Tumbleweed + troubleshooting
- Proyek asal: [BlankOn/manokwari](https://github.com/BlankOn/manokwari)
- Penerus resmi BlankOn (arah berbeda — GNOME Shell extension, bukan shell mandiri):
  [Praya](https://github.com/BlankOn/praya-gnome-shell-extension)