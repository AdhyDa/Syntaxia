# TECHNICAL DECISIONS & ARCHITECTURE — SYNTAXIA

Dokumen ini mencatat seluruh standar teknis, arsitektur perangkat lunak, tumpukan teknologi, keputusan desain yang telah disepakati, serta konvensi penulisan kode untuk game **Syntaxia**.

---

## 1. Teknologi & Versi

* **Game Engine:** Godot Engine 4.7.2-stable (Forward+ Renderer / 2D Snap to Pixel aktif)
* **Bahasa Pemrograman:** GDScript 2.0 (dengan Static Type Hints & Anotasi `@tool` untuk manajer data)
* **Viewport Resolution:** $1920 \times 1080$ (Mode `viewport`, VSync dinonaktifkan di config)
* **Pixel Density HUD:** Skala kanvas HUD `Vector2(4, 4)` dengan skala komponen turunan disesuaikan (~0.59x pada `PlayerUi`).
* **Plugins / Addons:** `res://addons/godot_ai/` (AI Assistant Bridge Runtime).

---

## 2. Struktur Folder & Peruntukan

```
Syntaxia/
├── .agent/rules/             # Aturan permanen untuk AI Agent
├── docs/                     # Dokumentasi teknis & handover proyek
├── addons/                   # Plugin internal (godot_ai runtime)
├── audio/                    # Musik BGM (ogg/mp3) dan SFX
├── content/                  # Implementasi konkret & varian game
│   ├── behavior/             # Perilaku AI musuh/NPC (follow, follow_path)
│   ├── character/            # Karakter konkret (player, Nara NPC, robot, book)
│   ├── collectible/          # Item bahan & koin konkret
│   │   ├── bahan/            # Rempah herbal (jahe, serai, air, kencur, beras, gulamerah, asamjawa)
│   │   └── coin/             # Koin gold
│   ├── environment/          # Objek lingkungan (kuali meja racik, teleporter, dekorasi)
│   ├── map/                  # Tilemap, tileset, peta desa (map_village.tscn)
│   ├── menu/                 # Title screen, UI menu, aset tombol
│   ├── potion/               # Resource & ikon jamu (wedangjahesereh, beraskencur, gepyokan)
│   └── team/                 # Resource tim damage (player_team.tres, npc_team.tres)
├── system/                   # Logika inti, arsitektur dasar, dan singleton
│   ├── behavior/             # Kelas dasar AI behaviour
│   ├── camera/               # CameraGrid controller
│   ├── character/            # Character base class, SpriteCharacter, LifeBar
│   ├── collectible/          # Collectible base class & ResourceCollectible
│   ├── color_correction/     # Color grading LUT shader
│   ├── damage/               # DamageArea & Hitbox system
│   ├── destroyable/          # Destroyable base class & ResourceDestroyable
│   ├── environment/          # EnvironmentArea, shape, fog, meteo
│   ├── input/                # HumanController input mapper
│   ├── inventory/            # PlayerInventory Autoload Singleton
│   ├── map/                  # Map base scene & controller
│   ├── particle/             # Particle system wrapper
│   ├── quest/                # QuestManager Autoload, RecipeParser, QuestDetailPopup
│   ├── spawner/              # GrassSpawner system
│   ├── stat/                 # ResourceStat, ResourceLife
│   ├── teleporter/           # Teleporter system
│   ├── transition/           # Fade transition
│   ├── ui/                   # ReceptacleBar, PlayerUi, GrimoireUI, theme
│   └── weapon/               # Weapon controller & ResourceWeapon
├── tests/                    # Automated runtime test runner & suites
└── project.godot             # Konfigurasi engine & autoload
```

---

## 3. Database & Penyimpanan Data

### A. Autoload Singletons
1. **`PlayerInventory` (`res://system/inventory/player_inventory.gd`):**
   * Mengelola kuantitas bahan rempah herbal dan potion di tas pemain.
   * Session-based (dibersihkan saat game ditutup dan saat `_ready()`).
   * Batas maksimal per bahan: `MAX_STACK = 5`.
2. **`QuestManager` (`res://system/quest/quest_manager.gd`):**
   * Singleton bertanda `@tool` untuk mengelola siklus hidup quest, level pemain, exp, dan koin perak.
   * Memuat dictionary data terpusat `QUEST_DATABASE: Dictionary`.

### B. Struktur Data `QUEST_DATABASE`
```gdscript
const QUEST_DATABASE: Dictionary = {
    1: {
        "id": 1,
        "title": "Quest 1: Pesanan Sang Pemula",
        "short_name": "Wedang Jahe",
        "client": "Nara (Penyihir Pemula yang Kedinginan)",
        "client_short": "Nara",
        "story": "...",
        "required_items": {"jahe": 1, "serai": 1, "air": 1},
        "result_item": "wedangjahesereh",
        "result_item_name": "Wedang Jahe Sereh",
        "reward_gold": 10,
        "reward_exp": 100,
        "ghost_template": "FUNGSI Ekstrak_Panas(Jahe, Sereh)\n    KEMBALIKAN Esensi_Hangat\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Wedang_Jahe()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi = Ekstrak_Panas(Jahe, Sereh)\n    Campurkan(esensi)\nAKHIR_PROSEDUR"
    },
    ...
}
```

---

## 4. Keputusan Arsitektur Kunci (Key Architectural Decisions)

### A. Dual-Layered Permanent Ghost-Text (Grimoire UI)
* **Masalah:** Properti bawaan `placeholder_text` pada `CodeEdit` di Godot 4 langsung menghilang saat pemain mulai mengetik karakter pertama.
* **Solusi Arsitektur:** Menumpuk dua node `CodeEdit` identik di atas aset bingkai kayu `code_terminal_ui_wood`:
  1. `GhostCodeEdit` (Layer Bawah): `editable = false`, `mouse_filter = MOUSE_FILTER_IGNORE`, font coklat transparan pudar `Color(0.45, 0.35, 0.25, 0.42)`. Nomor baris dimatikan (`gutters_draw_line_numbers = false`).
  2. `PlayerCodeEdit` (Layer Atas): `editable = true`, nomor baris aktif.
  3. **Penjajaran Horizontal (Gutter Alignment):** Posisi horizontal `GhostCodeEdit` digeser ke kanan sebesar `player_code_edit.get_total_gutter_width()` sehingga teks bayangan berada tepat di bawah teks ketikan pemain tanpa tergeser oleh nomor baris.
  4. **Sinkronisasi Scroll:** Di dalam `_process()`, nilai `scroll_vertical` dan `scroll_horizontal` pada `GhostCodeEdit` selalu disamakan dengan `PlayerCodeEdit`.

### B. Sistem Akordeon (Collapsible/Accordion) pada List Quest
* **Masalah:** Pemain membutuhkan akses riwayat quest yang sudah diselesaikan tanpa menutupi quest baru yang sedang aktif, serta membutuhkan daftar yang rapi jika quest bertambah banyak.
* **Solusi Arsitektur:**
  1. Menggunakan `ScrollContainer` berlatar `UI_QuestList.png`.
  2. Fungsi `QuestManager.get_tracked_quest_ids()` mengambil semua ID quest yang pernah diambil (`IN_PROGRESS`, `READY_TO_DELIVER`, `COMPLETED`).
  3. Setiap quest dirender sebagai kartu terpisah:
     * **Bilah Header (Clickable):** Menampilkan judul dan ringkasan status (`"Status: Quest X telah diselesaikan"` atau `"Status: Belum selesai (Sedang Berjalan)"`) dengan indikator panah `[ ▶ ]`.
     * **Panel Rincian:** Secara default berstatus **Shrink (`visible = false`)**.
     * **Interaksi Toggle:** Mengklik bilah header membuka (**Expand**, `[ ▼ ]`) atau menutup (**Shrink**, `[ ▶ ]`) panel rincian secara independen untuk tiap quest.

### C. Pembekuan Gerakan Pemain (Player Freeze Mechanism)
* **Masalah:** Saat dialog NPC, popup list quest, atau meja racik Grimoire terbuka, tombol pergerakan (WASD) tetap menggerakkan karakter pemain di latar belakang.
* **Solusi Arsitektur:** Fungsi terpusat `_freeze_player(freeze: bool)` diimplementasikan pada seluruh modul dialog dan modal UI:
  ```gdscript
  func _freeze_player(freeze: bool) -> void:
      for node in get_tree().get_nodes_in_group("player"):
          if "move_vector" in node:
              node.move_vector = Vector2.ZERO
          if "velocity" in node:
              node.velocity = Vector2.ZERO
          for child in node.get_children():
              if child is HumanController or child.name == "HumanController":
                  child.active = not freeze
  ```

### D. Companion Follow Target Reference (Opsi A)
* Node companion (`robot` dan `book`) di `map_village.tscn` menggunakan script `BehaviorFollow` dengan properti target diarahkan langsung ke `NodePath("../../player")`.
* Pengamanan tambahan dipasang untuk mencegah crash jika terjadi perpindahan scene atau teleportasi map.

### E. Rumus EXP dan Leveling Dinamis
* **Formula Max EXP:** $\text{Max EXP}(\text{Level}) = 100 + (\text{Level} - 1) \times 20$.
  * Naik Level 1 $\rightarrow$ Level 2: Butuh 100 EXP.
  * Naik Level 2 $\rightarrow$ Level 3: Butuh 120 EXP.
  * Naik Level 3 $\rightarrow$ Level 4: Butuh 140 EXP.
* **Akumulasi Surplus:** Jika pemain mendapatkan EXP melebihi Max EXP saat ini, kelebihan EXP disimpan dan diteruskan ke level berikutnya secara otomatis.

---

## 5. Ringkasan Keputusan Teknis yang Telah Disepakati

| Keputusan Teknis | Alasan / Rationale |
|---|---|
| **Data-Driven Quest System (`QUEST_DATABASE`)** | Memisahkan data quest dari logika UI sehingga penambahan Level 2, 3, dst. tidak memerlukan pengubahan kode tampilan. |
| **Bilah Akordeon Default Shrink** | Memastikan jendela daftar pesanan tetap ringkas, bersih, dan mudah dibaca oleh pemain meskipun telah menyelesaikan banyak quest. |
| **Kamus Nama Display Bahan (`ITEM_NAMES`)** | Menjembatani ID teknis bahan (seperti `serai`, `gulamerah`, `wedangjahesereh`) menjadi nama ramah pengguna (seperti `"Sereh"`, `"Gula Merah"`, `"Wedang Jahe Sereh"`). |
| **Pembersihan Instan Sebelum Re-render (`remove_child`)** | Menghindari bug penumpukan kartu pada frame yang sama akibat penundaan penghapusan oleh `queue_free()`. |
| **Tanda Centang Terpenuhi pada Bahan Quest Selesai** | Memberikan feedback visual yang jelas bahwa bahan pada quest lama sudah sukses dipenuhi tanpa membingungkan stok tas pemain saat ini. |
| **Bounds-Check Animasi `vframes` / `hframes`** | Mencegah engine Godot mengeluarkan error index out of bounds saat sprite sheet karakter hanya memiliki 1 baris. |
