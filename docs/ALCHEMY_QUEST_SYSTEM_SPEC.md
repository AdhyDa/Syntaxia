# Spesifikasi Teknis: Implementasi Level 1, Grimoire UI & Code Parser — Syntaxia

Dokumen ini berfokus pada **Fase Pengerjaan Saat Ini: Implementasi Level 1 (Quest 1 — Pesanan Sang Pemula)** beserta fondasi **Grimoire UI (*permanent ghost-text*)** dan **Code Parser (Fungsi & Prosedur)** pada proyek **Godot 4 (Target Web HTML5)**.

> **Batasan Ruang Lingkup (Scope):**
> 1. **Sudah Selesai:** Sistem *Autoload/Singleton*, *World*, *Looting*, dan *Inventory* pencarian bahan sudah selesai dikerjakan dan **tidak boleh dibuat ulang**.
> 2. **Fokus Fase Ini (Prioritas Utama):** Membangun **Level 1 secara utuh** dari awal penerimaan quest hingga penyerahan jamu selesai.
> 3. **Ditunda ke Fase Berikutnya:** Implementasi NPC, dialog, dan resep **Level 2 & Level 3 belum perlu dibuat pada fase ini** (cukup siapkan struktur kode yang modular agar mudah ditambahkan setelah Level 1 teruji).

---

## 1. Kontrak Integrasi dengan Sistem yang Sudah Ada

Sebelum membangun skrip Level 1 dan UI peracikan, sesuaikan pemanggilan API dengan skrip yang sudah tersedia di proyek:
* **Status Quest (`GameManager` / Quest Singleton):**
  * Membaca `active_quest_id` (fokus pada `1` untuk Level 1).
  * Mengelola transisi status misi (`NOT_STARTED` $\rightarrow$ `IN_PROGRESS` $\rightarrow$ `READY_TO_DELIVER` $\rightarrow$ `COMPLETED`).
  * Menambahkan imbalan **Koin Perak** dan **Reputasi (XP)** saat quest selesai.
* **Stok Tas (`InventoryManager` / Inventory Singleton):**
  * Memeriksa ketersediaan bahan mentah Level 1 (`jahe`, `sereh`, dan `air`).
  * Mengurangi stok bahan mentah (`jahe`, `sereh`, `air`) **hanya ketika validasi kode Level 1 berhasil 100%**.
  * Menambahkan item jamu jadi (`Wedang Jahe Sereh`) ke dalam tas pemain.

---

## 2. Alur Gameplay Level 1 (Quest, Racik & Delivery)

Alur permainan untuk Level 1 mengikuti tahapan berikut:

1. **Menerima Quest:** Pemain berinteraksi dengan NPC **Nara** di area desa (atau memilih Quest 1) untuk mengaktifkan `active_quest_id = 1`.
2. **Mengumpulkan Bahan:** *(Sudah tersedia via sistem Looting / Toko Mpok Sintaks yang sudah dibuat — target bahan: Jahe, Sereh, dan Air)*.
3. **Membuka Buku Sihir di Ruang Racik:** Pemain masuk ke kedai jamu dan berinteraksi dengan kuali/meja racik (`Empty Pot`) untuk membuka `GrimoireUI`. *(Pemain **tidak** memasukkan bahan secara manual ke kuali; bahan diproses melalui parameter kode).*
4. **Menulis & Menjalankan Kode:** Pemain mengetik ulang mantra kode Level 1 di atas *ghost-text* permanen pada `GrimoireUI`, lalu menekan tombol **Racik**.
5. **Validasi & Pembaruan Inventory:**
   * Jika **valid**: Stok `jahe` (1), `sereh` (1), dan `air` (1) dikurangi dari tas pemain, item **Wedang Jahe Sereh** (`Life Pot`) masuk ke tas, dan status quest berubah menjadi siap diserahkan (`READY_TO_DELIVER`).
   * Jika **error (*Mana Glitch*)**: Stok bahan di tas **tidak berkurang**, dan pesan kesalahan spesifik tampil di bar bawah UI.
6. **Menyerahkan Jamu (Delivery) & Quest Selesai:** Pemain kembali menemui NPC **Nara** untuk menyerahkan **Wedang Jahe Sereh**, lalu menerima imbalan **Koin Perak** dan **Reputasi (XP)**.

---

## 3. Spesifikasi Detail Level 1 (Quest 1: Pesanan Sang Pemula)

* **NPC Klien:** **Nara** (Penyihir pemula yang menggigil akibat gagal mengendalikan sihir es).
* **Materi Pembelajaran:** Perbedaan dasar **Fungsi** (proses ekstraksi yang mengembalikan nilai / *return value*) dan **Prosedur** (aksi penyeduhan tanpa *return value*).
* **Bahan yang Dibutuhkan:** `jahe` (1), `sereh` (1), `air` (1).
* **Hasil Jamu & Efek:** **Wedang Jahe Sereh** $\rightarrow$ Buff *Fire Resistance*.

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

### Aturan Validasi Parser Level 1
1. **Quest-Lock (Kunci Level):** Sistem menolak pembuatan jamu jika `active_quest_id != 1` atau jika pemain menuliskan sintaks/bahan resep level lain (misal: `Ekstrak_Stamina` / `Kencur_Hutan`).
2. **Validasi Fungsi (*Return Value*):**
   * Blok `FUNGSI Ekstrak_Panas(...)` wajib ada dan mengandung kata kunci `KEMBALIKAN`.
   * Pemanggilan `Ekstrak_Panas(...)` di dalam prosedur **wajib ditampung ke dalam variabel** (contoh: `esensi = Ekstrak_Panas(Jahe, Sereh)`). Jika dipanggil langsung tanpa ditampung variabel, munculkan pesan error *Mana Glitch*.
3. **Validasi Prosedur (*Void Action*):**
   * Blok `PROSEDUR Buat_Wedang_Jahe()` wajib ada dan **dilarang** mengandung kata kunci `KEMBALIKAN`.
   * Di dalamnya wajib memanggil urutan aksi: `Siapkan_Gelas()`, `Seduh_Air()`, dan `Campurkan(...)`.
4. **Sinkronisasi Parameter ke Inventory:**
   * Ekstrak argumen di dalam `Ekstrak_Panas(...)`, pastikan berisi `jahe` dan `sereh` (case-insensitive), lalu cek kecukupan stok `jahe`, `sereh`, dan `air` di `InventoryManager` sebelum memotong stok dan memberikan jamu.

---

## 4. Arsitektur UI Grimoire (`code_terminal_ui_wood`) — Permanent Ghost Text

Karena properti bawaan `placeholder_text` pada `CodeEdit` di Godot 4 otomatis menghilang saat pemain mengetik, gunakan teknik **Dual-Layered `CodeEdit`** di atas aset `code_terminal_ui_wood`:

* **Bar Atas (Header):** `QuestTitleLabel` menampilkan judul misi aktif (`Quest 1: Wedang Jahe Sereh`).
* **Area Krem Utama (`CodeContainer`):** Menumpuk dua node `CodeEdit` dengan ukuran, *padding*, *font*, dan *font size* yang **100% identik**:
  1. `GhostCodeEdit` (Layer Bawah): `editable = false`, `mouse_filter = MOUSE_FILTER_IGNORE`, warna font cokelat pudar transparan `Color(0.45, 0.35, 0.25, 0.42)`.
  2. `PlayerCodeEdit` (Layer Atas): Area ketik pemain, warna font tinta gelap pekat `Color(0.18, 0.11, 0.06, 1.0)`.
  3. Kedua node menggunakan `StyleBoxEmpty` pada override `normal`, `focus`, dan `read_only` agar latar krem bingkai kayu tetap terlihat.
  4. `scroll_vertical` dan `scroll_horizontal` pada `GhostCodeEdit` disinkronkan mengikuti `PlayerCodeEdit` di dalam `_process()`.
* **Bar Bawah:** `StatusLabel` untuk menampilkan umpan balik validasi (*"Racikan berhasil!"* atau pesan *Mana Glitch*) dan `BrewButton` (**Racik**) untuk mengeksekusi kode.
* **Pojok Kiri Bawah:** Tombol tutup (`X`) untuk menutup UI.

---

## 5. Catatan Arsitektur Masa Depan (Level 2 & Level 3 — Belum Diimplementasikan)

Struktur `QUEST_TEMPLATES` pada `GrimoireUI` dan fungsi validasi pada `RecipeParser` dirancang menggunakan `Dictionary` / `match active_quest_id` agar nantinya mudah diperluas untuk:
* **Level 2 (Quest 2 — Bara):** *Beras Kencur Magis* (`kencur_hutan`, `beras`, `air`) dengan konsep `FUNGSI` + `ULANGI 3 KALI`.
* **Level 3 (Quest 3 — Mbah Node):** *Gepyokan Mahadaya* (`empon_langka`, `gula_merah`, `asam_jawa`, `air`) dengan konsep `FUNGSI` + `PROSEDUR` berparameter dan penyaringan berulang.