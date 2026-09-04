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

### 🔜 Milestone 3 — Lepas Dependensi GNOME-Lock (Berikutnya)
Sebagian pre-work sudah lewat di Milestone 1 (lihat catatan per item):
- [x] ~~`gee-1.0` → `gee-0.8`~~ — **selesai** di Milestone 1
- [ ] `unique-3.0` → `GApplication`/`GtkApplication` — dependency sudah dihapus,
      **implementasi pengganti belum ada** (single-instance check di `main.vala`
      masih di-guard/nonaktif)
- [ ] `webkitgtk-3.0`/JSCore — dependency sudah dihapus, **keputusan Opsi A
      (port ke webkit2gtk-4.1) vs Opsi B (rewrite native GTK) belum diambil**,
      implementasi belum ada di 6+2 file yang di-stub
- [ ] `gnome-settings-daemon` (kontrol brightness) → ganti `org.freedesktop.login1`
      atau akses langsung `/sys/class/backlight` — **belum disentuh sama sekali**
- [ ] `libgnome-menu-3.0` → `GDesktopAppInfo`/`GAppInfoMonitor` + parsing manual
      `Categories=` — **belum disentuh**
- [ ] `libwnck-3.0` — opsi pragmatis: pertahankan (masih tersedia luas), reimplementasi
      EWMH manual via XCB jadi opsional/lanjutan
- [ ] **Session manager + requirement `mutter`** (`files/sessions/blankon.session.in`,
      `files/bin/blankon-session`) — paling dalam couplingnya, lihat `INVENTORY.md`
      bagian 2. Perlu pilih window manager pengganti Mutter (kandidat: `marco`,
      `openbox`, `xfwm4`) dan tulis ulang mekanisme peluncuran sesi

### ⏳ Milestone 4 — Finalisasi Identitas & Branding (Belum mulai)
- [ ] Rename D-Bus service name (`org.gnome.Panel` claim), GSettings schema ID
- [ ] Rename `blankon.desktop` → `manokwari.desktop`, `blankon-session` →
      `manokwari-session`, dsb (ditunda dari Milestone 0 karena isinya masih
      fungsional bergantung gnome-session — baru masuk akal setelah Milestone 3)
- [ ] Ikon/splash, keputusan kategori menu `Geo.BlankOn`

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