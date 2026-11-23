# Spesifikasi Teknis: Implementasi Level 1, Grimoire UI & Code Parser — Syntaxia

Dokumen ini mendokumentasikan spesifikasi teknis dan status implementasi **Level 1 (Quest 1 — Pesanan Sang Pemula)** beserta fondasi **Grimoire UI (*permanent ghost-text*)**, **Code Parser (Fungsi & Prosedur)**, dan **List Quest Akordeon** pada proyek **Godot 4 (Target Web HTML5)**.

> **Status Implementasi:** **SELESAI & TERUJI PENUH (COMPLETED & VERIFIED 100%)**

---

## 1. Kontrak Integrasi dengan Sistem

Implementasi Level 1 telah terhubung sempurna dengan sistem yang ada:
* **Status Quest (`QuestManager` Singleton):**
  * Membaca dan memperbarui `active_quest_id` (bernilai `1` untuk Level 1).
  * Mengelola transisi status misi (`NOT_STARTED` $\rightarrow$ `IN_PROGRESS` $\rightarrow$ `READY_TO_DELIVER` $\rightarrow$ `COMPLETED`).
  * Menambahkan imbalan **10 Koin Perak** dan **100 EXP** saat quest diserahkan ke Nara, menaikkan pemain ke **Level 2**.
* **Stok Tas (`PlayerInventory` Singleton):**
  * Memeriksa ketersediaan bahan mentah Level 1 (`jahe`: 1, `serai`: 1, dan `air`: 1).
  * Mengurangi stok bahan mentah **hanya ketika validasi kode Level 1 berhasil 100%**.
  * Menambahkan item jamu jadi `wedangjahesereh.tres` ke dalam tas pemain.

---

## 2. Alur Gameplay Level 1 (Quest, Racik & Delivery)

1. **Menerima Quest:** Pemain berinteraksi dengan NPC **Nara** di area desa menggunakan tombol **E** untuk mengaktifkan `QuestManager.start_quest(1)`.
2. **Mengumpulkan Bahan:** Pemain menjelajahi desa dan menginjak tanaman liar (`Grass`) untuk memanen `jahe`, `serai`, dan `air`.
3. **Membuka Buku Sihir di Ruang Racik:** Pemain masuk melalui teleporter ke Ruang Racik dan berinteraksi dengan Kuali Lapangan (`kuali.tscn`) menggunakan tombol **E** untuk membuka `GrimoireUI`.
4. **Menulis & Menjalankan Kode:** Pemain mengetikkan mantra kode Level 1 di atas *ghost-text* permanen pada `GrimoireUI`, lalu menekan tombol **Racik**.
5. **Validasi & Pembaruan Inventory:**
   * Jika **valid**: Stok `jahe` (1), `serai` (1), dan `air` (1) dipotong dari tas, item **Wedang Jahe Sereh** masuk ke tas, dan status quest berubah menjadi `READY_TO_DELIVER`.
   * Jika **error (*Mana Glitch*)**: Stok bahan di tas **tidak berkurang**, dan pesan kesalahan spesifik tampil di bar status bawah UI.
6. **Menyerahkan Jamu (Delivery) & Quest Selesai:** Pemain kembali menemui NPC **Nara** untuk menyerahkan **Wedang Jahe Sereh**, menerima imbalan **10 Koin Perak** dan **100 EXP**, lalu naik ke Level 2.

---

## 3. Spesifikasi Detail Level 1 (Quest 1: Pesanan Sang Pemula)

* **NPC Klien:** **Nara** (Penyihir pemula yang menggigil akibat gagal mengendalikan sihir es).
* **Materi Pembelajaran:** Perbedaan mendasar antara **Fungsi** (proses ekstraksi yang mengembalikan nilai / *return value*) dan **Prosedur** (aksi penyeduhan tanpa *return value* / void).
* **Bahan yang Dibutuhkan:** `jahe` (1), `serai` (1), `air` (1).
* **Hasil Jamu & Efek:** **Wedang Jahe Sereh** (`res://content/potion/FireResistance.png`).

### Template Kode (*Ghost Text* Level 1)
```text
FUNGSI Ekstrak_Panas(Jahe, Sereh)
    KEMBALIKAN Esensi_Hangat
AKHIR_FUNGSI

PROSEDUR Buat_Wedang_Jahe()
    Siapkan_Gelas()
    Seduh_Air()
    esensi = Ekstrak_Panas(Jahe, Sereh)
    Campurkan(esensi)
AKHIR_PROSEDUR
```

### Aturan Validasi Parser Level 1 (`RecipeParser`)
1. **Quest-Lock (Kunci Level):** Sistem menolak pembuatan jamu jika `active_quest_id != 1` atau jika pemain menuliskan sintaks/bahan resep level lain (misal: `kencur`, `beras`, `gulamerah`, `asamjawa`, `ekstrak_stamina`).
2. **Validasi Fungsi (*Return Value*):**
   * Blok `FUNGSI Ekstrak_Panas(Jahe, Sereh)` wajib ada dan mengandung kata kunci `KEMBALIKAN`.
   * Pemanggilan `Ekstrak_Panas(...)` di dalam prosedur **wajib ditampung ke dalam variabel** (contoh: `esensi = Ekstrak_Panas(Jahe, Sereh)`). Jika dipanggil lepas tanpa variabel, dimunculkan pesan *Mana Glitch*.
3. **Validasi Prosedur (*Void Action*):**
   * Blok `PROSEDUR Buat_Wedang_Jahe()` wajib ada dan **dilarang** mengandung kata kunci `KEMBALIKAN`.
   * Di dalamnya wajib memanggil urutan aksi: `Siapkan_Gelas()`, `Seduh_Air()`, dan `Campurkan(esensi)`.
4. **Sinkronisasi Parameter ke Inventory:**
   * Memeriksa ketersediaan stok nyata `jahe`, `serai`, dan `air` di `PlayerInventory`. Jika kurang, tampilkan rincian bahan yang kurang tanpa mengurangi tas.

---

## 4. Arsitektur UI Grimoire (`code_terminal_ui_wood`) — Permanent Ghost Text

* **Bar Atas (Header):** `QuestTitleLabel` menampilkan judul misi aktif (`[ QUEST 1: PESANAN SANG PEMULA ]`).
* **Area Krem Utama (`CodeContainer`):** Menumpuk dua node `CodeEdit` dengan ukuran dan font yang identik:
  1. `GhostCodeEdit` (Layer Bawah): `editable = false`, `mouse_filter = MOUSE_FILTER_IGNORE`, warna font `Color(0.45, 0.35, 0.25, 0.42)`, `gutters_draw_line_numbers = false`.
  2. `PlayerCodeEdit` (Layer Atas): Area ketik pemain, warna font pekat `Color(0.18, 0.11, 0.06, 1.0)`, nomor baris aktif.
  3. **Kompensasi Gutter:** Koordinat X `GhostCodeEdit` di-offset sejajar `player_code_edit.get_total_gutter_width()` agar teks bayangan lurus presisi di bawah teks ketikan pemain.
  4. **Sinkronisasi Scroll:** `ghost_code_edit.scroll_vertical` disinkronkan dengan `player_code_edit.scroll_vertical` setiap frame.
* **Bar Bawah:** `StatusLabel` menampilkan umpan balik validasi, dan `BrewButton` (**Racik**) mengeksekusi validasi.
* **Pembekuan Kontrol:** Karakter pemain dibekukan (`_freeze_player(true)`) saat antarmuka grimoire aktif.

---

## 5. Sistem Akordeon pada List Quest (`UI_QuestList.png`)

Jendela List Quest (`quest_detail_popup.tscn` & `.gd`) dirancang menggunakan pola **Akordeon (Collapsible/Accordion)** untuk menampung riwayat quest pemain:
* **Daftar Kumulatif:** Menampilkan seluruh quest yang pernah diambil pemain via `QuestManager.get_tracked_quest_ids()`. Quest yang telah selesai tidak hilang saat quest baru dimulai.
* **Default State (Shrink):** Secara default, seluruh kartu quest tertutup dan hanya menampilkan bilah header interaktif dengan indikator `[ ▶ ]` serta status ringkas:
  * Quest Selesai: `"Status: Quest X telah diselesaikan"` (Hijau).
  * Quest Berjalan: `"Status: Belum selesai (Sedang Berjalan)"` (Coklat Keemasan).
  * Jamu Siap: `"Status: Jamu telah siap! (Bawa ke [Nama Klien])"`.
* **Interaksi Klik (Expand):** Mengklik bilah header membuka rincian lengkap quest (Klien, Cerita, Bahan bercentang `✓ Terpenuhi` atau live counter `- 0/1`, Status detail, dan Imbalan) serta mengubah ikon panah menjadi `[ ▼ ]`.
* **ScrollContainer:** Memastikan daftar quest dapat di-scroll dengan mulus di atas latar lembaran perkamen `UI_QuestList.png`.
