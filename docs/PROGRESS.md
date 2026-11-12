# SYNTAXIA — AI AGENT SYSTEM MEMORY & PROGRESS LOG

Dokumen ini berfungsi sebagai **memori persisten dan konteks kerja** untuk AI Agent yang melanjutkan pengembangan proyek **Syntaxia (Godot Engine 4.7+)**. 
Dokumen ini mencatat seluruh arsitektur, histori implementasi dari awal, struktur file, aturan konvensi, serta panduan modifikasi teknis.

---

## 1. Konvensi Arsitektur Proyek

Proyek ini memisahkan secara ketat antara **Sistem Inti** dan **Konten**:
* `res://system/`: Logika dasar, abstract/base class, base scene, resource template, dan singleton manager.
* `res://content/`: Varian konkret, prefab spesifik, aset visual, partikel, peta, dan data item turunan.

### Konvensi Layer Fisika (2D Physics Layers)
* **Layer 1:** `Wall` (Dinding & batas fisik dunia)
* **Layer 2:** `Character` (Collision tubuh karakter umum)
* **Layer 3 (Bitmask 4):** `Hitbox` (Area penerima damage senjata)
* **Layer 5:** `Player` (Didaftarkan via `player_assignor.gd` dengan `COLLISION_MASK_PLAYER = 5`)

---

## 2. Rangkuman Histori Perkembangan (Progress Log)

### [Milestone 1] Fondasi Sistem Collectible & Migrasi Destroyable
* **Tujuan Awal:** Menambahkan logika item collectible berbasis parent script dan scene destroyable.
* **Tindakan yang Dilakukan:**
  1. Memindahkan aset & scene `crate`, `grass`, `pot` dari `content/destroyable/` ke `content/collectible/bahan/` serta memperbarui referensi di `tileset.tres` dan file `.import`.
  2. Membuat singleton autoload `PlayerInventory` di `res://system/inventory/player_inventory.gd` (didaftarkan di `project.godot`).
  3. Membuat resource dasar `ResourceCollectible` (`system/collectible/resource_collectible.gd`).
  4. Membuat base scene dan script `Collectible` (`system/collectible/collectible.gd` & `.tscn`).
  5. Menambahkan kemampuan `spawn_drop()` dan properti `@export var drop_item_scene` pada parent `system/destroyable/destroyable.gd`.

### [Milestone 2] Pembuatan Item Bahan & Varian Destroyable Map
* **Tujuan:** Membuat drop item untuk Jahe dan membuat objek destroyable beserta item drop untuk 6 bahan lainnya (dengan aturan penamaan tanpa tanda `_`).
* **Hasil:**
  * **Jahe:** `jahe.tres`, `jahebahan.tscn`, terhubung ke `jahe.tscn`.
  * **Serai:** `serai.tres`, `seraibahan.tscn`, `serai.tscn`.
  * **Air:** `air.tres`, `airbahan.tscn`, `air.tscn`.
  * **Kencur:** `kencur.tres`, `kencurbahan.tscn`, `kencur.tscn`.
  * **Beras:** `beras.tres`, `berasbahan.tscn`, `beras.tscn`.
  * **Gula Merah:** `gulamerah.tres`, `gulamerahbahan.tscn`, `gulamerah.tscn`.
  * **Asam Jawa:** `asamjawa.tres`, `asamjawabahan.tscn`, `asamjawa.tscn`.

### [Milestone 3] Logika Rumput Khusus (Grass Loot & Spawner)
* **Tujuan:** Rumput menjadi sumber drop acak bahan herbal berbobot, hancur hanya saat disentuh pemain, dan bersiklus respawn otomatis.
* **Hasil:**
  1. **Script Rumput:** `content/collectible/bahan/grass.gd` (`extends Destroyable`).
     * Memiliki area sentuh `PlayerTouchArea` (Layer 5).
     * Kebal terhadap serangan senjata (`hitbox.monitorable = false`).
     * Memiliki tabel persentase drop rate berbobot (*Weighted Drop Table*).
  2. **Grass Spawner:** `system/spawner/grass_spawner.gd` & `.tscn`.
     * Kuota rumput aktif diatur sebesar 80% dari total `Marker2D`.
     * Cooldown respawn 15 detik setelah item diambil atau kedaluwarsa.
     * Peluang 10% respawn di titik asal yang sama.
     * Evaluasi kamera: Rumput **tidak boleh respawn** jika koordinatnya terlihat di viewport kamera pemain.
  3. **Pemasangan di Map:** Menambahkan `GrassSpawner` lengkap dengan **10 titik `Marker2D`** di `content/map/map_village.tscn`.

### [Milestone 4] Penyempurnaan Mekanik Drop, Sesi Inventory, & HUD UI
* **Tujuan:**
  1. Inventory backend terhapus saat game ditutup (sesi bersih).
  2. Item jatuh dan membal ke tanah terlebih dahulu sebelum bisa diambil (tidak instan).
  3. Menampilkan UI item yang terkumpul di bawah bar EXP pada HUD pemain.
* **Hasil:**
  1. `PlayerInventory`: Menghapus data penyimpanan saat `NOTIFICATION_WM_CLOSE_REQUEST` dan saat `_ready()`.
  2. `Collectible`: Ditambahkan fungsi `_spawn_scatter_and_bounce_fx()` (lompatan parabola 16–24 px dengan jeda pengambilan ~0.4 detik).
  3. `PlayerUi`: Ditambahkan `CollectibleContainer` (`HFlowContainer`) di `system/ui/player_ui.tscn` dan sinkronisasi ikon $14 \times 14$ px + jumlah bahan di `system/ui/player_ui.gd`.

---

## 3. Rincian Teknis Komponen & File Kunci

### A. Backend Inventory (`system/inventory/player_inventory.gd`)
* **Status:** Autoload Singleton (`PlayerInventory`).
* **Kapasitas:** `MAX_STACK = 5` per `item_id`.
* **Sifat Data:** Session-only (terhapus otomatis saat game ditutup).
* **Fungsi Utama:**
  * `add_item(item_id: String, amount: int = 1) -> bool` (me-return `false` jika stack penuh).
  * `has_item(item_id: String) -> bool`
  * `get_item_count(item_id: String) -> int`
  * `remove_item(item_id: String, amount: int = 1) -> bool`
  * `get_all_items() -> Dictionary`
  * `clear()` dan `clear_saved_data()`

### B. Base Collectible (`system/collectible/collectible.gd`)
* **Node:** `Area2D` (collision_mask: Layer 5 / Player).
* **Fitur:**
  * `lifetime = 30.0`: Bertahan 30 detik di tanah.
  * `blink_duration = 5.0`: Berkedip di 5 detik terakhir.
  * `_spawn_scatter_and_bounce_fx()`: Melompat dan membal sebelum aktif diambil.
  * `finished(success: bool)`: Memancarkan sinyal selesai (diambil atau waktu habis) ke Spawner.

### C. Rumput / Grass (`content/collectible/bahan/grass.gd` & `.tscn`)
* **Node:** `CharacterBody2D` (`Grass extends Destroyable`).
* **Drop Rates Default:**
  * `air`: 25.0 (Common)
  * `beras`: 25.0 (Common)
  * `serai`: 15.0 (Uncommon)
  * `gulamerah`: 15.0 (Uncommon)
  * `jahe`: 10.0 (Rare)
  * `asamjawa`: 5.0 (Very Rare)
  * `kencur`: 5.0 (Epic)

### D. Spawner Rumput (`system/spawner/grass_spawner.gd`)
* **Target Count:** `target_grass_count = roundi(markers.size() * spawn_ratio)` (80%).
* **Cooldown:** `cooldown_seconds = 15.0`.
* **Pengecekan Kamera:** `_is_position_visible_by_camera(world_pos: Vector2)` menggunakan `CameraGrid` / `Camera2D` dengan `screen_margin_buffer = 40.0`.

### E. Player HUD UI (`system/ui/player_ui.gd` & `.tscn`)
* **Node:** `%CollectibleContainer` (`HFlowContainer`) di bawah `%ExpBar`.
* **Rendering:** Mendengarkan sinyal `item_added`, `item_removed`, `inventory_loaded`. Menampilkan ikon dari `ITEM_TEXTURES` dan teks jumlah font `ThaleahFat.ttf` ukuran 12.

---

## 4. Lokasi & Panduan Modifikasi Cepat

| Ingin Mengubah Apa? | File yang Diedit | Baris / Parameter |
|---|---|---|
| **Persentase Drop Rate Bahan** | `content/collectible/bahan/grass.gd` | `@export var drop_rates` (Baris 15–25) atau via Inspector `grass.tscn` |
| **Batas Maksimal Stack Item** | `system/inventory/player_inventory.gd` | `const MAX_STACK: int = 5` (Baris 8) |
| **Waktu Cooldown Respawn Rumput** | `system/spawner/grass_spawner.gd` | `@export var cooldown_seconds: float = 15.0` (Baris 8) |
| **Persentase Rumput Aktif di Map** | `system/spawner/grass_spawner.gd` | `@export var spawn_ratio: float = 0.8` (Baris 11) |
| **Peluang Respawn di Titik Sama** | `system/spawner/grass_spawner.gd` | `@export var same_spot_chance: float = 0.1` (Baris 14) |
| **Durasi Item di Tanah Sebelum Hilang** | `system/collectible/collectible.gd` | `@export var lifetime: float = 30.0` (Baris 9) |
| **Jarak Lemparan Item Saat Pecah** | `system/collectible/collectible.gd` | `var scatter_dist: float = randf_range(16.0, 24.0)` (Baris 54) |
| **Ukuran Ikon Item di HUD Layar** | `system/ui/player_ui.gd` | `icon_rect.custom_minimum_size = Vector2(14, 14)` (Baris 78) |

---

## 5. Rencana Fitur Lanjutan (Backlog / Roadmap)

Fitur-fitur ini telah dibahas dengan pengguna namun **belum dikerjakan** (tunggu instruksi pengguna selanjutnya):
1. **Sistem Peracikan Jamu / Alkimia (Crafting System):**
   * Memanfaatkan bahan yang tersimpan di `PlayerInventory` untuk diracik di `kuali.tscn` berdasarkan `recipe_scroll.gd` dan target misi `recent_quest.gd`.
2. **Sistem Pembelian Bahan Menggunakan Koin (Shop System):**
   * NPC Toko yang memungkinkan pembelian bahan herbal langsung menggunakan `Gold` pemain.
3. **Floating Text / Popup Toast:**
   * Menampilkan teks melayang kecil (misal: `"+1 Jahe"` atau `"Bahan Penuh!"`) saat pemain mencoba mengambil item.
