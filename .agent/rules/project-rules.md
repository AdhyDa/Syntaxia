# PROJECT RULES & AI AGENT GUIDELINES — SYNTAXIA

Dokumen ini adalah **pedoman permanen** bagi setiap AI Agent yang bekerja pada repositori proyek game **Syntaxia**. Seluruh instruksi, konvensi, dan batasan di bawah ini bersifat mengikat dan wajib dipatuhi.

---

## 1. Aturan Penamaan File & Asset (STRICT)

1. **LARANGAN KARAKTER UNDERSCORE PADA SCENE BAHAN/COLLECTIBLE:**
   * Seluruh nama scene `.tscn` dan resource `.tres` untuk bahan rempah/collectible baru **DILARANG KERAS** menggunakan karakter garis bawah (`_`).
   * *Contoh Benar:* `gulamerah.tres`, `gulamerahbahan.tscn`, `asamjawa.tres`, `asamjawabahan.tscn`, `kencur.tres`.
   * *Contoh Salah (DILARANG):* `gula_merah.tres`, `gula_merah_bahan.tscn`, `asam_jawa.tres`.
2. **Struktur Penamaan Item:**
   * Resource Data: `res://content/collectible/bahan/{namaitem}.tres`
   * Scene Drop (Pickup di tanah): `res://content/collectible/bahan/{namaitem}bahan.tscn`
   * Scene Objek Lapangan (Destroyable): `res://content/collectible/bahan/{namaitem}.tscn`
   * Tekstur Ikon: `res://content/collectible/bahan/{namaitem}.png`

---

## 2. Standar Arsitektur Game & Engine

1. **Engine Version:** Godot Engine 4.7.2+ Stable (Official).
2. **Bahasa Pemrograman:** GDScript dengan Static Typing (`var x: int = 0`, `func foo() -> void:`).
3. **Layer Collision Baku:**
   * **Layer 1:** World / Dinding / Collision solid.
   * **Layer 2:** Hitbox (Area serang/terima damage senjata).
   * **Layer 3:** Hurtbox.
   * **Layer 5:** **Player Body (Karakter Pemain Utama).**
     * Seluruh collectible dan deteksi sentuhan rumput (`PlayerTouchArea`) wajib mendeteksi **Layer 5**.
4. **Pola Spawn (Spawn Zone System):**
   * Gunakan sistem **Spawn Zone** berbasis area persegi (`zone_size` / `Rect2`), **BUKAN** membuat puluhan node `Marker2D` individual.
   * Pertahankan visualisasi debug di editor menggunakan anotasi `@tool` dan fungsi `_draw()`.
   * Spawn baru wajib memenuhi dua kriteria utama:
     * Berjarak aman dari rumput aktif lain (`min_distance`).
     * Berada di luar pandangan kamera pemain saat respawn berlangsung (`_is_position_visible_by_camera()`).

---

## 3. Ketentuan Inventory & State Persistence

1. **Session-Only Storage:**
   * Inventory pemain bersifat sementara untuk sesi bermain yang sedang aktif.
   * Data inventory **TIDAK BOLEH** disimpan permanen antar sesi.
   * File `user://player_inventory.json` wajib dibersihkan saat game dimulai (`_ready()`) dan saat window ditutup (`NOTIFICATION_WM_CLOSE_REQUEST`).
2. **Kapasitas Stack:**
   * Maksimal item per jenis bahan adalah **5 stack** (`MAX_STACK = 5`).
   * Pemain yang sudah memiliki 5 buah item tidak boleh memungut item sejenis di tanah.

---

## 4. Ketentuan UI & UX Consistency

1. **Font Standar:**
   * Gunakan font pixel art yang seragam: `res://assets/fonts/ThaleahFat.ttf`.
2. **Ukuran Ikon HUD:**
   * Slot bahan di HUD (`player_ui.tscn`) menggunakan ukuran $14 \times 14$ pixel dengan `TextureRect.STRETCH_KEEP_ASPECT_CENTERED`.
3. **Feedback Visual Item Drop:**
   * Item yang keluar dari tanaman wajib memiliki efek lontaran parabola (*scatter & bounce*) sejauh 16–24 px dengan jeda mendarat 0.4s sebelum bisa dipungut (`can_be_collected = false`).
   * Item di tanah memiliki durasi hidup 30 detik, berkedip pada 5 detik terakhir, lalu memudar halus (*fade out*).

---

## 5. Hal-Hal yang DILARANG Diubah Tanpa Persetujuan

1. **Jangan Mengubah Sistem Combat & Health Eksisting:**
   * Node `ResourceLife`, `ResourceDamage`, dan logika damage bawaan karakter tidak boleh dirombak tanpa izin eksplisit.
2. **Jangan Mengubah Struktur Map Tanpa Kebutuhan Jelas:**
   * Node-node lingkungan seperti `EnvironmentArea`, `Teleporter`, `BatasMap`, dan `Tilemap` tidak boleh dihapus atau dipindah posisinya sembarangan.
3. **Jangan Mengubah Autoload Singleton Lain:**
   * Autoload selain yang berhubungan langsung dengan tugas (misal `PlayerInventory`) harus dibiarkan utuh.

---

## 6. Protokol Kerja & Komunikasi AI Agent

1. **Verifikasi Kode Sebelum Melaporkan:**
   * Selalu lakukan validasi dan scan filesystem (`filesystem_manage(op="scan")`) setelah membuat/mengedit file.
   * Periksa log editor/game via `godot-ai` MCP server untuk memastikan nol error GDScript.
2. **Transparan & Akurat:**
   * Jangan mengklaim fitur selesai jika kodenya belum dibuat dan diuji.
   * Bedakan dengan tegas antara fitur yang sudah selesai (*completed*), sedang berjalan (*in progress*), dan rencana (*backlog*).
3. **Format Komunikasi:**
   * Berikan penjelasan yang terstruktur, tenang, solutif, dan profesional dalam Bahasa Indonesia.
   * Sertakan markdown file link (`file:///...`) untuk setiap file yang disebutkan dalam percakapan.
