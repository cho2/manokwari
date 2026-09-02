# Inventory: GNOME Coupling — Manokwari Reborn

Disusun sebagai bagian dari Milestone 0 (Roadmap Manokwari Reborn). Hasil audit langsung
terhadap source code (`src/`, `files/`, `data/`) di titik commit `f542632`.

Tujuan dokumen ini: memetakan semua titik ketergantungan ke GNOME secara konkret (file +
baris), supaya Milestone 3 ("Lepas Dependensi GNOME-Lock") punya scope yang jelas dan tidak
ada kejutan di tengah jalan.

---

## 1. Application Identity

| Item | Lokasi | Status |
|---|---|---|
| Unique.App ID | `src/main.vala:26` | ✅ Sudah diganti `id.or.blankonlinux.Manokwari` → `io.github.cho2.Manokwari` |
| D-Bus session name claim `org.gnome.Panel` | `src/main.vala:35` | ⏳ Belum — diklaim di session bus supaya `gnome-session` tahu "panel sudah start". Akan hilang begitu saja begitu gnome-session dilepas (Milestone 3). |

## 2. GNOME Session Manager Protocol (coupling paling dalam)

Ini bagian paling signifikan — bukan sekadar "pakai library GNOME", tapi manokwari didesain
untuk **hidup di dalam sesi gnome-session**, dengan Mutter sebagai window manager wajibnya.

- `src/panel-session-manager.vala` — implementasi client penuh untuk `org.gnome.SessionManager`
  dan `org.gnome.SessionManager.ClientPrivate` (protokol registrasi client ke gnome-session).
- `src/panel-shell.vala` — mengimplementasikan `org.gnome.SessionManager.EndSessionDialog`
  (dialog yang dipanggil gnome-session saat logout/shutdown), plus referensi string `org.gnome.Shell`.
- `files/sessions/blankon.session.in` + `files/sessions/meson.build` — file definisi sesi GNOME.
  **Temuan penting:** daftar `RequiredComponents` di sini secara eksplisit memasukkan **`mutter`**
  sebagai komponen wajib, plus daftar panjang `org.gnome.SettingsDaemon.*` yang disusun otomatis
  berdasarkan versi GSD terpasang. Diinstal ke path `gnome-session/sessions` (path spesifik gnome-session).
- `files/bin/blankon-session` — script peluncur sesi. Baris terakhir: `exec gnome-session --session blankon "$@"`.
  Juga ada hook `blankon-session-try-installer` yang spesifik BlankOn (tidak relevan lagi).
- `files/xsessions/blankon.desktop` — entry sesi di login manager. `DesktopNames=Manokwari;GNOME`,
  teks `Comment=` masih menyebut "BlankOn".

**→ Implikasi Milestone 3:** bukan sekadar ganti dependency satu-satu, tapi ganti seluruh mekanisme
startup sesi. Perlu diputuskan window manager pengganti Mutter (kandidat pragmatis: `marco` — fork
Metacity dari MATE, EWMH-compliant penuh dan masih aktif dipelihara — atau `openbox`/`xfwm4`), dan
tulis ulang launcher sesi sendiri yang tidak menuntut gnome-session/GSD.

**Sengaja belum disentuh di Milestone 0:** rename file (`blankon.desktop`, `blankon.session.in`,
`blankon-session`) ditunda ke Milestone 3. Me-rename filenya sekarang tanpa mengganti isinya cuma
akan menghasilkan artefak yang membingungkan (mis. file bernama `manokwari-session` yang masih
meng-exec `gnome-session --session blankon`).

## 3. GNOME Settings Daemon (GSD)

- `src/panel-window.vala` — kontrol brightness layar lewat D-Bus interface
  `org.gnome.SettingsDaemon.Power` / `org.gnome.SettingsDaemon.Power.Screen`.
- **Pengganti realistis:** `org.freedesktop.login1.Session` (systemd-logind punya method brightness)
  atau akses langsung ke `/sys/class/backlight`.

## 4. GSettings Schema ber-namespace `org.gnome.*`

- `org.gnome.system.locale` — `src/main.vala:4`
- `org.gnome.desktop.background` — `src/panel-desktop-html.vala:19`
- Disediakan paket `gsettings-desktop-schemas`, tersedia luas lintas-DE (bukan eksklusif GNOME
  environment). **Prioritas rendah** untuk diganti — aman dipertahankan untuk sementara.

## 5. libgnome-menu / GMenu

- Dipakai di: `src/panel-desktop.vala`, `src/panel-desktop-data.vala`, `src/xdg-data.vala`,
  `src/panel-menu-content.vala`.
- File `files/menus/manokwari-applications.menu` sendiri **sudah format freedesktop.org Desktop
  Menu Specification standar** (DOCTYPE merujuk ke `freedesktop.org/standards/menu-spec`) — bukan
  format proprietary GNOME. Yang perlu diganti cuma *library parsing-nya* di kode (Milestone 3),
  bukan file XML-nya.
- Catatan konten (bukan teknis): ada kategori menu `<Name>Geo.BlankOn</Name>` yang branded BlankOn.
  Perlu keputusan terpisah apakah dipertahankan atau dihapus.

## 6. libwnck

- Dipakai di: `src/panel-window.vala`. Wrapper GNOME di atas EWMH/ICCCM — lihat diskusi roadmap
  soal opsi pragmatis (pertahankan) vs opsi murni (reimplementasi EWMH manual via XCB).

## 7. WebKitGTK3

- Dipakai di: `src/panel-desktop-html.vala`, `src/panel-menu-html.vala`.
- **Keputusan besar tertunda** (lihat roadmap Milestone 3, Opsi A vs Opsi B).

## 8. libunique

- `src/main.vala:26` — App ID string sudah didebranding (lihat commit terkait), tapi library
  `unique-3.0` itu sendiri masih dipakai apa adanya. Penggantian penuh ke `GApplication` tetap
  masuk scope Milestone 3.

---

## Ringkasan Prioritas untuk Milestone 3

| Prioritas | Item | Alasan |
|---|---|---|
| Tinggi | Session manager + Mutter requirement | Paling dalam, mempengaruhi semua yang lain |
| Tinggi | libunique → GApplication | Cepat dikerjakan, tidak ada alasan menunda |
| Tinggi | WebKitGTK3 (keputusan A/B) | Menentukan besarnya rewrite UI |
| Sedang | gnome-settings-daemon (brightness) | Fungsional tapi scope kecil |
| Sedang | libgnome-menu → GDesktopAppInfo | Sudah ada file XML standar, tinggal ganti consumer |
| Rendah | libwnck | Masih tersedia luas, bisa dipertahankan dulu |
| Rendah | GSettings `org.gnome.*` schemas | Paket umum lintas-DE, tidak mendesak |