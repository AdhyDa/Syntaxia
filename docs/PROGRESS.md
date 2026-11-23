# SYNTAXIA — AI AGENT SYSTEM MEMORY & PROGRESS LOG

Dokumen ini berfungsi sebagai **memori persisten dan konteks kerja** untuk AI Agent yang melanjutkan pengembangan proyek **Syntaxia (Godot Engine 4.7+)**. 
Dokumen ini mencatat seluruh arsitektur, histori implementasi dari awal, struktur file, aturan konvensi, serta panduan modifikasi teknis.

---

## 1. Konvensi Arsitektur Proyek

Proyek ini memisahkan secara ketat antara **Sistem Inti** dan **Konten**:
* `res://system/`: Logika dasar, abstract/base class, base scene, resource template, singleton manager, sistem UI umum, dan quest engine.
* `res://content/`: Varian konkret, prefab spesifik, aset visual, karakter, NPC, peta, dan data item turunan.

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
  1. Memindahkan aset & scene `crate`, `grass`, `pot` dari `content/destroyable/` ke `content/collectible/bahan/` serta memperbarui referensi di `tileset.tres`.
  2. Membuat singleton autoload `PlayerInventory` di `res://system/inventory/player_inventory.gd`.
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
     * Evaluasi kamera: Rumput tidak boleh respawn jika koordinatnya terlihat di viewport kamera pemain.
  3. **Pemasangan di Map:** Menambahkan `GrassSpawner` lengkap dengan 10 titik `Marker2D` di `content/map/map_village.tscn`.

### [Milestone 4] Penyempurnaan Mekanik Drop, Sesi Inventory, & HUD UI
* **Tujuan:**
  1. Inventory backend terhapus saat game ditutup (sesi bersih).
  2. Item jatuh dan membal ke tanah terlebih dahulu sebelum bisa diambil (tidak instan).
  3. Menampilkan UI item yang terkumpul di bawah bar EXP pada HUD pemain.
* **Hasil:**
  1. `PlayerInventory`: Menghapus data penyimpanan saat `NOTIFICATION_WM_CLOSE_REQUEST` dan saat `_ready()`.
  2. `Collectible`: Ditambahkan fungsi `_spawn_scatter_and_bounce_fx()` (lompatan parabola 16–24 px dengan jeda pengambilan ~0.4 detik).
  3. `PlayerUi`: Ditambahkan `CollectibleContainer` (`HFlowContainer`) di `system/ui/player_ui.tscn` dan sinkronisasi ikon $14 \times 14$ px + jumlah bahan di `system/ui/player_ui.gd`.

### [Milestone 5] Implementasi Penuh Level 1 (Quest 1: Pesanan Sang Pemula) & Grimoire UI
* **Tujuan:** Mengimplementasikan siklus penuh peracikan jamu Level 1 berbasis kode (Fungsi vs Prosedur) dan interaksi penyerahan ke NPC Nara.
* **Hasil:**
  1. **NPC Nara:** Interaksi dialog menggunakan tombol E di desa (`nara_interaction.gd`, `nara_dialog_ui.tscn`). Memberikan quest "Wedang Jahe Sereh".
  2. **Kuali Ruang Racik:** Interaksi kuali lapangan di Ruang Racik (`kuali.gd`, `kuali.tscn`) untuk membuka Grimoire UI.
  3. **Dual-Layered Grimoire UI (`grimoire_ui.tscn`, `grimoire_ui.gd`):** Menggunakan aset `code_terminal_ui_wood`. Lapisan bawah `GhostCodeEdit` (bayangan teks permanen tanpa nomor baris) dan lapisan atas `PlayerCodeEdit` dengan sinkronisasi scroll permanen serta alignment horizontal berbasis lebar gutter.
  4. **Educational RecipeParser Level 1 (`recipe_parser.gd`):**
     * Memvalidasi `FUNGSI Ekstrak_Panas(Jahe, Sereh)` wajib memiliki `KEMBALIKAN` dan hasilnya ditampung ke variabel.
     * Memvalidasi `PROSEDUR Buat_Wedang_Jahe()` (aksi void) wajib memanggil `Siapkan_Gelas()`, `Seduh_Air()`, dan `Campurkan(esensi)`.
     * Menolak kode jika terdapat sintaks resep level lain (Quest-Lock).
  5. **Integrasi Stok Tas:** Memotong 1 Jahe, 1 Sereh, 1 Air jika sukses, dan memberikan item jamu `wedangjahesereh.tres`.
  6. **Siklus Delivery & Reward:** Pemain menyerahkan jamu ke Nara $\rightarrow$ menerima 10 Koin Perak dan 100 EXP (naik ke Level 2).

### [Milestone 6] Generalisasi Sistem Quest, Akordeon List Quest, & Companion Follow
* **Tujuan:** Menghilangkan seluruh hardcode quest agar sistem siap menampung Level 1, 2, 3 dst. secara modular, serta menghadirkan jendela List Quest akordeon interaktif.
* **Hasil:**
  1. **Pusat Database Quest (`QuestManager`):** Menyimpan `QUEST_DATABASE` untuk Quest 1, 2, 3, kamus nama ramah pengguna `ITEM_NAMES`, fungsi helper `get_item_display_name()`, rumus EXP dinamis ($100 + (\text{level}-1)\times 20$), serta fungsi `get_tracked_quest_ids()`.
  2. **HUD Recent Quest Dinamis (`recent_quest.gd`):** Papan gantung dinamis dengan animasi ayun `Tween`, menampilkan live counter bahan dari tas, mendeteksi jamu siap antar, dan status selesai.
  3. **Jendela List Quest Akordeon (`quest_detail_popup.gd` & `.tscn`):**
     * Menggunakan latar kertas parchment `UI_QuestList.png` dan `ScrollContainer`.
     * Menampilkan seluruh riwayat quest yang pernah diterima pemain (quest yang telah selesai tetap ada saat menerima quest baru).
     * **Sistem Akordeon (Expand & Shrink):**
       * Secara default **shrink** dengan indikator `[ ▶ ]`.
       * Menampilkan keterangan status ringkas: `"Status: Quest X telah diselesaikan"` untuk quest selesai, dan `"Status: Belum selesai (Sedang Berjalan)"` untuk quest aktif.
       * Ketika diklik, kartu mengembang (**Expand**) menjadi `[ ▼ ]` menampilkan rincian Klien, Cerita, Bahan (dengan centang hijau terpenuhi jika selesai), Status detail, dan Imbalan.
       * Ketika diklik kembali, kartu menutup (**Shrink**) kembali ke `[ ▶ ]`.
     * Jika belum ada quest, menampilkan pesan ramah tanpa tanda `"-"`.
  4. **Player Freeze System:** Pemain membeku dan tidak bisa digerakkan dengan WASD selama berdialog dengan NPC, membuka Grimoire UI, atau membuka popup List Quest.
  5. **Companion Follow (Book & Robot):** Memperbaiki perilaku pengikut di `map_village.tscn` agar mengikuti pemain dengan aman.
  6. **Perbaikan Bounds Check Animasi:** Memperbaiki `sprite_character.gd` agar aman saat membaca sprite dengan `vframes = 1`.
  7. **Automated Test Suite:** `tests/test_quest_runner.gd` & `.tscn` menguji seluruh integrasi secara otomatis di engine runtime (100% Passed).

---

## 3. Rincian Teknis Komponen & File Kunci

### A. Quest Manager (`system/quest/quest_manager.gd`)
* **Status:** Autoload Singleton (`QuestManager`), `@tool`.
* **Database Quest:** `QUEST_DATABASE: Dictionary` menyimpan data lengkap `id`, `title`, `short_name`, `client`, `client_short`, `story`, `required_items`, `result_item`, `reward_gold`, `reward_exp`, dan `ghost_template`.
* **Fungsi Utama:**
  * `get_quest_data(quest_id: int) -> Dictionary`
  * `get_active_quest_data() -> Dictionary`
  * `get_tracked_quest_ids() -> Array[int]`
  * `get_item_display_name(item_id: String) -> String`
  * `is_delivery_ready(quest_id: int) -> bool`
  * `get_max_exp_for_level(lvl: int) -> int`
  * `add_exp(amount: int)` & `add_gold(amount: int)`
  * `start_quest(quest_id: int)` & `complete_quest(quest_id: int)`

### B. List Quest Akordeon (`system/quest/quest_detail_popup.gd`)
* **Node:** `Control` berlatar `UI_QuestList.png`.
* **Scroll & List:** `%ScrollContainer` menampung `%QuestListContainer`.
* **Perilaku Akordeon:**
  * Tombol header quest memicu toggle `details_margin.visible = not details_margin.visible`.
  * Indikator panah otomatis berganti antara `[ ▶ ]` (shrink) dan `[ ▼ ]` (expand).
  * Menghapus child node dengan `remove_child(child)` sebelum `child.queue_free()` untuk mencegah bug duplikasi instan di frame yang sama.

### C. Grimoire UI (`system/ui/grimoire_ui.gd`)
* **Node:** `Control` berlatar `code_terminal_ui_wood`.
* **Komponen:**
  * `%GhostCodeEdit`: `editable = false`, `gutters_draw_line_numbers = false`, offset posisi x mengikuti `player_code_edit.get_total_gutter_width()`.
  * `%PlayerCodeEdit`: Input kode aktif pemain.
  * Sinkronisasi scroll: `ghost_code_edit.scroll_vertical = player_code_edit.scroll_vertical`.

### [Milestone 9] Sistem Toko 2 Arah "Mpok Sintaks" (Beli & Jual Bahan Herbal)
* **Tujuan:** Mengimplementasikan Shopping System 2 Arah (Beli & Jual) di peta desa dengan ekonomi Hardcore untuk 7 bahan rempah herbal.
* **Hasil & Implementasi:**
  1. **Ekonomi Hardcore & Helper (`system/quest/quest_manager.gd`):**
     * Konstanta `ITEM_PRICES: Dictionary` untuk 7 bahan (air: 6/1, beras: 6/1, serai: 9/1, gulamerah: 9/1, jahe: 12/2, asamjawa: 18/3, kencur: 18/3).
     * Helper: `get_shop_item_ids()`, `get_item_buy_price()`, `get_item_sell_price()`, `spend_gold()`, dan alias `var gold: int`.
     * Proteksi jamu jadi (`wedangjahesereh`, `beraskencur`, `gepyokan`) tidak dijual di toko.
  2. **Antarmuka ShopUI (`system/ui/shop_ui.tscn` & `shop_ui.gd`):**
     * Menggunakan aset pixel art `res://content/ui/shop_ui/` (`TEXTURE_FILTER_NEAREST`).
     * Tab BUY dan SELL dinamis (`tab_normal`, `tab_hover`, `tab_pressed`).
     * Plakat toko `shop_name` ("Mpok Sintaks") dan live counter koin perak.
     * GridContainer 3 kolom dengan 7 kartu (`shop_item_card`).
     * Penguncian slot kosong (`slot_empty_locked`) khusus mode SELL jika stok tas 0.
     * Panel kanan dengan detail item, stok tas (`Stok: X/5`), harga beli/jual, tombol BUY/SELL dinamis, dan tombol BACK.
     * Instant cleanup kartu menggunakan `remove_child(child)` sebelum `child.queue_free()`.
     * Pembekuan gerak pemain (`_freeze_player(true)`) saat toko terbuka dan unfreeze saat ditutup (BACK atau ESC).
  3. **Node Toko di Desa (`content/map/map_village.tscn` & `content/environment/toko_interaction.gd`):**
     * Area deteksi `TokoInteractionArea` (mask 2 & 5) di depan bangunan Toko.
     * Label prompt mengambang `[E] Toko Mpok Sintaks` dengan kompensasi skala unscaled.
     * Menangani interaksi tombol E untuk membuka `ShopUI` di CanvasLayer `Hud`.
  4. **Pengujian Otomatis (`tests/test_shop_runner.gd` & `.tscn`):**
     * 22/22 test assertion passed 100% di runtime game engine.

---

## 4. Lokasi & Panduan Modifikasi Cepat

| Ingin Mengubah Apa? | File yang Diedit | Baris / Parameter |
|---|---|---|
| **Data Quest & Resep Baru (Quest 2, 3)** | `system/quest/quest_manager.gd` | `const QUEST_DATABASE: Dictionary` |
| **Harga Beli & Jual Bahan di Toko** | `system/quest/quest_manager.gd` | `const ITEM_PRICES: Dictionary` |
| **Kamus Nama Display Bahan** | `system/quest/quest_manager.gd` | `const ITEM_NAMES: Dictionary` |
| **Rumus Kenaikan EXP per Level** | `system/quest/quest_manager.gd` | `func get_max_exp_for_level(lvl: int)` |
| **Papan Gantung Recent Quest** | `recent_quest.gd` | `func update_quest_display()` |
| **Tampilan Akordeon List Quest** | `system/quest/quest_detail_popup.gd` | `func _create_quest_card(q_id: int)` |
| **Antarmuka & Transaksi Toko** | `system/ui/shop_ui.gd` | `system/ui/shop_ui.tscn` & `.gd` |
| **Pemicu Interaksi Toko di Map** | `content/environment/toko_interaction.gd` | `open_shop()`, `_ready()` |
| **Aturan Validasi Parser Kode** | `system/quest/recipe_parser.gd` | `func _validate_level_1(code: String)` |
| **Persentase Drop Rate Bahan** | `content/collectible/bahan/grass.gd` | `@export var drop_rates` |
| **Batas Maksimal Stack Item** | `system/inventory/player_inventory.gd` | `const MAX_STACK: int = 5` |
| **Waktu Cooldown Respawn Rumput** | `system/spawner/grass_spawner.gd` | `@export var cooldown_seconds: float = 15.0` |

---

## 5. Rencana Fitur Lanjutan (Backlog / Roadmap)

1. **Pembuatan NPC Bara & Konten Level 2 (Beras Kencur):**
   * Menempatkan NPC Bara di area desa dan memperluas `RecipeParser` untuk konsep perulangan `ULANGI 3 KALI`.
2. **Pembuatan NPC Mbah Node & Konten Level 3 (Gepyokan):**
   * Menempatkan NPC Mbah Node dan mengaktifkan peracikan jamu tolak bala.
3. **[SELESAI] Sistem Toko & Pembelian dengan Koin (Toko Mpok Sintaks):**
   * Sistem transaksi 2 arah (Beli & Jual) bahan herbal dengan harga hardcore economy, slot locking, dan UI pixel art lengkap.
4. **Floating Toast Notification:**
   * Menampilkan teks melayang kecil (misal: `"+1 Jahe"`, `"+10 Koin"`) di atas kepala pemain.
