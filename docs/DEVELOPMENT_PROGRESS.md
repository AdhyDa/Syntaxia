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
* [x] **Jeda Pengambilan (Delayed Pickup):** `can_be_collected = false` saat di udara; baru menjadi `true` setelah mendarat.
* [x] **Masa Hidup 30 Detik:** Item bertahan 30 detik di tanah, berkedip di 5 detik terakhir, lalu memudar transparan dan `queue_free()` jika diabaikan.

### E. Grass Spawner & Kamera (Sistem Marker2D)
* [x] **Sistem Spawner Berbasis Marker2D:** [`res://system/spawner/grass_spawner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.gd) & [`grass_spawner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.tscn).
* [x] **Kuota 80%:** Selalu mempertahankan 80% rumput aktif dari total marker di map (`spawn_ratio = 0.8`).
* [x] **10 Marker2D Terpasang:** Terpasang di [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn) (8 rumput aktif, 2 titik cadangan).
* [x] **Cooldown 15 Detik:** Menghitung jeda 15 detik setelah item diambil atau kedaluwarsa sebelum memunculkan rumput pengganti.
* [x] **Peluang 10% Titik Asal:** 10% peluang respawn di titik yang sama jika kosong dan di luar layar.
* [x] **Pencegahan Respawn di Dalam Layar (No Pop-in):** Fungsi `_is_position_visible_by_camera()` mengecek bounding box kamera `CameraGrid`.

### F. Backend Inventory Pemain
* [x] **Singleton Autoload:** `PlayerInventory` di [`res://system/inventory/player_inventory.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/inventory/player_inventory.gd).
* [x] **Batas Maksimal 5:** `MAX_STACK = 5`.
* [x] **Session-Only Storage:** File penyimpanan `user://player_inventory.json` dihapus saat game ditutup (`NOTIFICATION_WM_CLOSE_REQUEST`) dan saat `_ready()`.

### G. HUD UI Bahan Terkumpul, EXP & Koin
* [x] **Container Dinamis:** Node `%CollectibleContainer` (`HFlowContainer`) di [`res://system/ui/player_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/player_ui.tscn).
* [x] **Rendering Item & Potion:** Mendukung tekstur rempah herbal serta jamu jadi (`wedangjahesereh`, `beraskencur`, `gepyokan`) di [`res://system/ui/player_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/player_ui.gd).
* [x] **EXP & Leveling Bar:** Menghubungkan `%ExpBar` dan label level (`LV. X`) dengan rumus dinamis EXP maksimal: $100 + (\text{level} - 1) \times 20$.
* [x] **Koin Perak:** Sinkronisasi nilai koin live dengan sinyal `gold_changed` dari `QuestManager`.

### H. Sistem Quest & Level 1 (Quest 1: Pesanan Sang Pemula)
* [x] **Interaksi NPC Nara:** Scene dialog [`res://content/character/NPC/nara_dialog_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/character/NPC/nara_dialog_ui.tscn) dan script interaksi [`nara_interaction.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/character/NPC/nara_interaction.gd) (tombol interaksi E).
* [x] **Siklus Quest:** `NOT_STARTED` $\rightarrow$ `IN_PROGRESS` $\rightarrow$ `READY_TO_DELIVER` $\rightarrow$ `COMPLETED`.
* [x] **Kuali & Ruang Racik:** Interaksi kuali [`res://content/environment/kuali.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/environment/kuali.gd) dengan tombol E, animasi `kuali_idle` dan `kuali_proses`.
* [x] **Grimoire UI dengan Dual-Layer Permanent Ghost-Text:** [`res://system/ui/grimoire_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/grimoire_ui.tscn) dan [`grimoire_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/grimoire_ui.gd) menggunakan aset `code_terminal_ui_wood`. Lapisan bawah `GhostCodeEdit` (tanpa nomor baris) dan lapisan atas `PlayerCodeEdit` dengan offset gutter dinamis dan sinkronisasi scroll permanen.
* [x] **Educational RecipeParser Level 1:** [`res://system/quest/recipe_parser.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/recipe_parser.gd) memvalidasi `FUNGSI Ekstrak_Panas(Jahe, Sereh)` yang wajib memiliki `KEMBALIKAN` dan ditampung ke variabel, serta `PROSEDUR Buat_Wedang_Jahe()` (void) yang memanggil `Siapkan_Gelas()`, `Seduh_Air()`, dan `Campurkan(esensi)`.
* [x] **Integrasi Stok Tas:** Memotong 1 Jahe, 1 Sereh, 1 Air hanya jika validasi 100% sukses, dan menambahkan item jamu `wedangjahesereh.tres` ke tas pemain.
* [x] **Imbalan Quest 1:** 10 Koin Perak dan 100 EXP diserahkan saat pemain kembali ke Nara, menaikkan pemain ke Level 2.

### I. Generalisasi Sistem Quest & Akordeon List Quest
* [x] **Pusat Database Quest (`QuestManager`):** [`res://system/quest/quest_manager.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_manager.gd) menyimpan database terpusat (`QUEST_DATABASE`) untuk Quest 1, 2, dan 3, kamus nama ramah pengguna `ITEM_NAMES`, fungsi helper `get_item_display_name()`, dan fungsi `get_tracked_quest_ids()`.
* [x] **Recent Quest HUD (Papan Gantung Kanan Atas):** [`res://recent_quest.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recent_quest.gd) & [`recent_quest.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recent_quest.tscn) dengan animasi ayun lembut (`Tween`), membaca bahan dinamis dari database quest aktif, menampilkan live count, status jamu siap antar, dan status selesai.
* [x] **Jendela List Quest / "Lihat Quest" Berbasis Akordeon:** [`res://system/quest/quest_detail_popup.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_detail_popup.tscn) & [`quest_detail_popup.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_detail_popup.gd) menggunakan aset `UI_QuestList.png`:
  * Menggunakan `ScrollContainer` untuk menampung banyak quest secara modular.
  * Menampilkan seluruh riwayat quest yang pernah diterima pemain (quest yang telah selesai tetap ada saat quest baru diambil).
  * **Sistem Akordeon (Expand & Shrink):**
    * Default: **Shrink** (hanya menampilkan bilah header dengan indikator `[ ▶ ]` dan status ringkas).
    * Quest Selesai menampilkan keterangan: `"Status: Quest X telah diselesaikan"`.
    * Quest Berjalan menampilkan keterangan: `"Status: Belum selesai (Sedang Berjalan)"`.
    * Diklik $\rightarrow$ **Expand** (membuka rincian Klien, Cerita, Bahan, Status detail, Imbalan, dan indikator panah berubah menjadi `[ ▼ ]`).
    * Diklik kembali $\rightarrow$ **Shrink** (menutup kembali ke `[ ▶ ]`).
  * Jika belum ada quest yang diambil: Menampilkan pesan ramah tanpa tanda `"-"`.

### J. Penanganan Kontrol Pemain & Companion
* [x] **Freeze Player:** Pemain dibekukan (tidak bisa bergerak via WASD) saat dialog NPC, membuka Grimoire UI, atau membuka popup List Quest.
* [x] **Companion Follow (Book & Robot):** Node `robot` dan `book` di [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn) dikonfigurasi mengikuti target `../../player` dengan pengamanan sinyal `teleported`.
* [x] **Perbaikan Bounds Check Animasi:** [`res://system/character/sprite_character.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/character/sprite_character.gd) menambahkan validasi `vframes` dan `hframes` untuk mencegah error *out of bounds* pada sprite 1 baris.

### K. Automated Runtime Test Suite
* [x] **Runner Pengujian Otomatis:** [`res://tests/test_quest_runner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_quest_runner.gd) & [`test_quest_runner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_quest_runner.tscn) menguji seluruh siklus quest, perhitungan leveling/EXP, status papan gantung, serta interaksi akordeon expand/shrink secara live di runtime engine (100% Passed).

### L. Sistem Toko 2 Arah "Mpok Sintaks" (Beli & Jual Bahan Herbal)
* [x] **Ekonomi Hardcore QuestManager:** [`res://system/quest/quest_manager.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_manager.gd) — Ditambahkan `ITEM_PRICES` (7 bahan herbal), `get_shop_item_ids()`, `get_item_buy_price()`, `get_item_sell_price()`, `spend_gold()`. Harga: Air 6/1, Beras 6/1, Serai 9/1, Gula Merah 9/1, Jahe 12/2, Asam Jawa 18/3, Kencur 18/3.
* [x] **ShopUI Scene & Script:** [`res://system/ui/shop_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/shop_ui.tscn) & [`shop_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/shop_ui.gd) — UI 1920×1080 pixel art dengan banner "Mpok Sintaks", tab BUY/SELL, panel kiri GridContainer 7 kartu item (3 kolom), panel kanan detail + harga + stok, koin live, tombol BUY/SELL dinamis, tombol BACK. Menggunakan aset `shop_ui_left`, `shop_ui_right`, `shop_item_card`, `slot_selected`, `slot_normal`, `slot_empty_locked`.
* [x] **Interaksi Toko:** [`res://content/environment/toko_interaction.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/environment/toko_interaction.gd) — Script extend Sprite2D terpasang pada node `Toko` di map_village. Membuat Area2D dinamis (RectangleShape2D 210×190), prompt label `[E] Toko Mpok Sintaks`, deteksi pemain, buka ShopUI via tombol E, freeze/unfreeze player.
* [x] **Integrasi map_village.tscn:** [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn) — Node `Toko` (Sprite2D) dipasangi script `toko_interaction.gd`. ShopUI di-inject ke `PlayerUI/Hud` saat interaksi berlangsung.
* [x] **Validasi Transaksi:** Mode BUY — disabled jika koin kurang ATAU stok tas ≥ 5. Mode SELL — `slot_empty_locked` jika stok 0, disabled jika stok = 0. Item jamu jadi (wedangjahesereh, beraskencur, gepyokan) **tidak termasuk** dalam daftar toko.
* [x] **Test Runner Toko:** [`res://tests/test_shop_runner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_shop_runner.gd) & [`test_shop_runner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_shop_runner.tscn) — **22/22 PASSED 100%** (Ekonomi QuestManager 6, ShopUI 6, Mode SELL 5, Node Toko 5).

---

## 2. Fitur yang Belum Dikerjakan (Planned / Backlog)

1. **Implementasi Penuh Quest 2 (Bara — Pejuang Kelelahan):**
   * Pembuatan NPC Bara di map, pembuatan scene dialog Bara, dan pengenalan sintaks perulangan `ULANGI 3 KALI` pada `RecipeParser`. (Catatan: Data quest, bahan, dan template sudah siap di `QUEST_DATABASE`).
2. **Implementasi Penuh Quest 3 (Mbah Node — Sesepuh Desa):**
   * Pembuatan NPC Mbah Node di map, dialog ritual tolak bala, dan peracikan jamu Gepyokan Mahadaya.
3. ~~**Sistem Toko & Pembelian dengan Koin** — **SELESAI** (Lihat bagian L)~~
4. **Notifikasi Teks Melayang (Floating Toast Notification):**
   * Teks kecil seperti `"+1 Jahe"` atau `"Bahan Penuh!"` di atas kepala pemain.
5. **Efek Suara (Audio SFX):**
   * SFX meracik jamu, SFX membuka grimoire, dan SFX penyelesaian quest.

---

## 3. File yang Terakhir Dimodifikasi / Ditambahkan

1. [`res://system/quest/quest_manager.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_manager.gd)
2. [`res://system/quest/quest_detail_popup.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_detail_popup.gd)
3. [`res://system/quest/quest_detail_popup.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_detail_popup.tscn)
4. [`res://recent_quest.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recent_quest.gd)
5. [`res://recent_quest.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recent_quest.tscn)
6. [`res://system/ui/grimoire_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/grimoire_ui.gd)
7. [`res://system/ui/grimoire_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/grimoire_ui.tscn)
8. [`res://system/ui/player_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/player_ui.gd)
9. [`res://system/character/sprite_character.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/character/sprite_character.gd)
10. [`res://tests/test_quest_runner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_quest_runner.gd)
11. [`res://tests/test_quest_runner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_quest_runner.tscn)
12. [`res://system/ui/shop_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/shop_ui.gd)
13. [`res://system/ui/shop_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/shop_ui.tscn)
14. [`res://content/environment/toko_interaction.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/environment/toko_interaction.gd)
15. [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn)
16. [`res://tests/test_shop_runner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_shop_runner.gd)
17. [`res://tests/test_shop_runner.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/tests/test_shop_runner.tscn)
