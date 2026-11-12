# DEVELOPMENT PROGRESS — SYNTAXIA

Dokumen ini melacak status pengerjaan fitur secara jujur dan transparan berdasarkan kode sumber aktual yang telah terpasang dan teruji di dalam engine Godot.

---

## 1. Fitur yang Sudah Selesai (Completed & Verified)

Fitur-fitur berikut telah sepenuhnya diimplementasikan, diverifikasi di runtime engine Godot 4.7, dan berfungsi sesuai spesifikasi:

### A. Fondasi Destroyable & Collectible
* [x] **Base Class Destroyable:** [`res://system/destroyable/destroyable.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/destroyable/destroyable.gd) & [`destroyable.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/destroyable/destroyable.tscn). Memiliki sistem HP (`ResourceLife`), Hitbox, partikel hancur, getar, flash putih, dan fungsi `spawn_drop()`.
* [x] **Base Class Collectible:** [`res://system/collectible/collectible.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/collectible/collectible.gd) & [`collectible.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/collectible/collectible.tscn). `Area2D` yang mendeteksi tabrakan pemain di Layer 5.
* [x] **Resource Data Item:** [`res://system/collectible/resource_collectible.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/collectible/resource_collectible.gd) untuk menyimpan `item_id`, `display_name`, dan `icon`.

### B. Aset & Scene 7 Bahan Rempah Herbal (Aturan Penamaan Tanpa Underscore)
* [x] **Jahe:** [`jahe.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/jahe.tres), [`jahebahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/jahebahan.tscn), [`jahe.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/jahe.tscn).
* [x] **Serai:** [`serai.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/serai.tres), [`seraibahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/seraibahan.tscn), [`serai.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/serai.tscn).
* [x] **Air:** [`air.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/air.tres), [`airbahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/airbahan.tscn), [`air.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/air.tscn).
* [x] **Kencur:** [`kencur.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/kencur.tres), [`kencurbahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/kencurbahan.tscn), [`kencur.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/kencur.tscn).
* [x] **Beras:** [`beras.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/beras.tres), [`berasbahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/berasbahan.tscn), [`beras.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/beras.tscn).
* [x] **Gula Merah:** [`gulamerah.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/gulamerah.tres), [`gulamerahbahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/gulamerahbahan.tscn), [`gulamerah.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/gulamerah.tscn).
* [x] **Asam Jawa:** [`asamjawa.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/asamjawa.tres), [`asamjawabahan.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/asamjawabahan.tscn), [`asamjawa.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/asamjawa.tscn).

### C. Logika Tanaman Rumput Liar (Grass)
* [x] **Script Khusus Grass:** [`res://content/collectible/bahan/grass.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/grass.gd) (`extends Destroyable`).
* [x] **Hancur Saat Disentuh:** Menggunakan child `PlayerTouchArea` (Area2D Layer 5).
* [x] **Kebal Senjata:** Menonaktifkan `hitbox.monitorable = false` dan meng-override `take_damage()` agar tidak mempan ditebas senjata pemain.
* [x] **Weighted Drop Rate Table:** Peluang berbobot acak:
  * Air: 25% | Beras: 25% | Serai: 15% | Gula Merah: 15% | Jahe: 10% | Asam Jawa: 5% | Kencur: 5%.

### D. Fisika & Siklus Hidup Item di Tanah
* [x] **Scatter & Bounce Parabola:** Item melompat melengkung ke atas lalu membal jatuh ke tanah sejauh 16–24 px selama ~0.4 detik.
* [x] **Jeda Pengambilan (Delayed Pickup):** `can_be_collected = false` saat di udara; baru menjadi `true` setelah mendarat, sehingga pemain harus mendekat dan tidak langsung terambil otomatis saat menginjak rumput.
* [x] **Masa Hidup 30 Detik:** Item bertahan 30 detik di tanah, berkedip di 5 detik terakhir (detik ke-25 s/d 30), lalu memudar transparan (*fade out*) dan `queue_free()` jika diabaikan.

### E. Grass Spawner & Kamera (Sistem Marker2D)
* [x] **Sistem Spawner Berbasis Marker2D:** [`res://system/spawner/grass_spawner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.gd) & [`grass_spawner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.tscn).
* [x] **Kuota 80%:** Selalu mempertahankan 80% rumput aktif dari total marker di map (`spawn_ratio = 0.8`).
* [x] **10 Marker2D Terpasang:** Terpasang di [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn) (8 rumput aktif, 2 titik cadangan).
* [x] **Cooldown 15 Detik:** Menghitung jeda 15 detik setelah item diambil atau kedaluwarsa sebelum memunculkan rumput pengganti.
* [x] **Peluang 10% Titik Asal:** 10% peluang respawn di titik yang sama jika kosong dan di luar layar.
* [x] **Pencegahan Respawn di Dalam Layar (No Pop-in):** Fungsi `_is_position_visible_by_camera()` mengecek bounding box kamera `CameraGrid` agar rumput baru hanya muncul di luar layar monitor pemain.

### F. Backend Inventory Pemain
* [x] **Singleton Autoload:** `PlayerInventory` di [`res://system/inventory/player_inventory.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/inventory/player_inventory.gd).
* [x] **Batas Maksimal 5:** `MAX_STACK = 5`. Pemain yang sudah memiliki 5 item jenis tersebut tidak bisa memungut lagi dan melewatinya.
* [x] **Session-Only Storage:** File penyimpanan `user://player_inventory.json` dihapus saat game ditutup (`NOTIFICATION_WM_CLOSE_REQUEST`) dan selalu dibersihkan di `_ready()`, sehingga inventory bersih tiap sesi baru.

### G. HUD UI Bahan Terkumpul
* [x] **Container Dinamis:** Node `%CollectibleContainer` (`HFlowContainer`) terpasang di [`res://system/ui/player_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/player_ui.tscn) di bawah `%ExpBar`.
* [x] **Sinkronisasi Otomatis:** [`res://system/ui/player_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/player_ui.gd) merender slot bahan aktif (ikon 14x14 px + label `x{count}` font `ThaleahFat.ttf`) saat sinyal `item_added`/`item_removed` dipancarkan.

---

## 2. Fitur yang Sedang Berjalan / Sebagian Selesai (In Progress)

* [ ] **Integrasi Data Inventory ke UI Resep & Quest:**
  * File [`recipe_scroll.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recipe_scroll.gd) dan [`recent_quest.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recent_quest.gd) saat ini masih menggunakan string dummy ("Jahe: 0/1", "Gula Merah: 0/1", "Lumina Leaves: 3").
  * Belum dihubungkan secara dinamis untuk membaca kuantitas asli dari `PlayerInventory.get_item_count("jahe")`.

---

## 3. Fitur yang Belum Dikerjakan (Planned / Backlog)

Fitur-fitur ini sudah dibahas dengan pengguna namun **disepakati untuk ditunda sementara** hingga sistem dasar selesai:

1. **Sistem Peracikan Kuali (Crafting / Alchemy Station):**
   * Pemanfaatan node [`res://content/environment/kuali.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/environment/kuali.tscn) sebagai tempat pemain menekan tombol interaksi untuk meracik jamu (misal: Jahe + Gula Merah + Air $\rightarrow$ Jamu Wedang Jahe).
2. **Sistem Toko & Pembelian dengan Koin:**
   * NPC Toko yang memungkinkan pembelian bahan herbal menggunakan koin pemain (`Gold`).
3. **Notifikasi Teks Melayang (Floating Toast Notification):**
   * Teks kecil seperti `"+1 Jahe"` atau `"Bahan Penuh!"` yang muncul di atas kepala pemain saat menyentuh item.
4. **Efek Suara (Audio SFX):**
   * SFX rumput patah/terinjak saat hancur dan SFX memungut item (*chime / pickup sound*).

---

## 4. Progress Terakhir Secara Spesifik (Update Terakhir)

1. **Pengembalian Sistem Spawn ke Marker2D (Sesuai Preferensi Pengguna):**
   * Mengembalikan [`grass_spawner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.gd) ke sistem kuota 80% berbasis `Marker2D` (`spawn_ratio = 0.8`), cooldown 15s, 10% same spot chance, dan deteksi off-screen.
   * Mengembalikan container node `Markers` pada [`grass_spawner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.tscn).
   * Mengembalikan seluruh 10 node `Marker1` sampai `Marker10` dan tag `[editable path="GrassSpawner"]` di [`map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn).
   * Menyesuaikan kembali [`grass.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/grass.gd) dan [`collectible.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/collectible/collectible.gd) ke referensi `origin_marker: Marker2D`.
2. **Dokumen Handover & Aturan Permanen:**
   * File [`docs/KNOWN_ISSUES.md`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/docs/KNOWN_ISSUES.md) dan [`.agent/rules/project-rules.md`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/.agent/rules/project-rules.md) telah selesai disusun.
3. **Verifikasi Runtime:**
   * Diuji via Godot MCP tool `project_run`, status `live` dan berjalan lancar tanpa error GDScript.

---

## 5. File yang Terakhir Dimodifikasi

1. [`res://system/spawner/grass_spawner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.gd)
2. [`res://system/spawner/grass_spawner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.tscn)
3. [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn)
4. [`res://content/collectible/bahan/grass.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/grass.gd)
5. [`res://system/collectible/collectible.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/collectible/collectible.gd)
6. [`docs/DEVELOPMENT_PROGRESS.md`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/docs/DEVELOPMENT_PROGRESS.md)
7. [`docs/TECHNICAL_DECISIONS.md`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/docs/TECHNICAL_DECISIONS.md)

---

## 6. Tugas Berikutnya yang Harus Dilanjutkan

Ketika sesi baru dimulai, tugas prioritas berikutnya adalah:
1. **Menghubungkan `PlayerInventory` dengan `recent_quest.gd` & `recipe_scroll.gd`:**
   * Ubah teks quest agar menampilkan kuantitas dinamis `PlayerInventory.get_item_count("jahe")` / `1` dan `PlayerInventory.get_item_count("gulamerah")` / `1`.
2. **Implementasi Interaksi Kuali (`kuali.tscn`):**
   * Beri Area2D interaksi pemain (tekan tombol aksi, misal `E` atau `Spasi` / tombol interaksi).
   * Tampilkan resep pembuatan jamu dan kurangi bahan dari `PlayerInventory` jika syarat terpenuhi.
