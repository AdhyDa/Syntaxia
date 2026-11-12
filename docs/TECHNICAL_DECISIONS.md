# TECHNICAL DECISIONS & ARCHITECTURE — SYNTAXIA

Dokumen ini mencatat seluruh standar teknis, arsitektur perangkat lunak, tumpukan teknologi, keputusan desain yang telah disepakati, serta konvensi penulisan kode untuk game **Syntaxia**.

---

## 1. Teknologi & Versi

* **Game Engine:** Godot Engine 4.7.2-stable (Forward+ Renderer / 2D Snap to Pixel aktif)
* **Bahasa Pemrograman:** GDScript 2.0 (dengan Static Type Hints)
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
│   └── music/
├── content/                  # Implementasi konkret & varian game
│   ├── behavior/             # Perilaku AI musuh/NPC (follow, follow_path)
│   ├── character/            # Karakter konkret (samurai_green, ninja_blue, pig, samurai_blue)
│   ├── collectible/          # Item bahan & koin konkret
│   │   ├── bahan/            # Rempah herbal (jahe, serai, air, kencur, beras, gulamerah, asamjawa)
│   │   └── coin/             # Koin gold
│   ├── environment/          # Objek lingkungan (kuali, dekorasi)
│   ├── map/                  # Tilemap, tileset, peta desa (map_village.tscn)
│   ├── menu/                 # Title screen, UI menu, aset tombol
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
│   ├── spawner/              # GrassSpawner system
│   ├── stat/                 # ResourceStat, ResourceLife
│   ├── teleporter/           # Teleporter system
│   ├── transition/           # Fade transition
│   ├── ui/                   # ReceptacleBar, PlayerUi, theme
│   └── weapon/               # Weapon controller & ResourceWeapon
└── project.godot             # Konfigurasi engine & autoload
```

---

## 3. Database & Penyimpanan Data

### Model Penyimpanan: Session-Based Singleton Memory
* **Lokasi File:** `user://player_inventory.json` (hanya digunakan selama runtime sesi jika diperlukan, dan dibersihkan saat sesi berakhir).
* **Manajer Data:** Autoload `PlayerInventory` (`res://system/inventory/player_inventory.gd`).
* **Format Data:**
  ```json
  {
    "jahe": 3,
    "air": 5,
    "serai": 1
  }
  ```
* **Keputusan Teknis (Session-Only):**
  * Sesuai permintaan pengguna, data inventory **tidak bersifat permanen lintas sesi**.
  * Saat `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` dan saat inisialisasi game `_ready()`, file penyimpanan dihapus dengan `DirAccess.remove_absolute(SAVE_PATH)` dan memori `items.clear()` dieksekusi.

---

## 4. Komponen Kunci & Pola Arsitektur (Components & Patterns)

### A. Pola Pewarisan Scene & Script (Inherited Scenes)
* **Prinsip:** Logika umum selalu berada di `system/`, sedangkan instance di `content/` hanya mengonfigurasi properti via `@export`.
* **Contoh:**
  * `Destroyable` (`system/destroyable/destroyable.gd`) $\rightarrow$ diwarisi oleh `Grass` (`content/collectible/bahan/grass.gd`).
  * `Collectible` (`system/collectible/collectible.gd`) $\rightarrow$ diwarisi oleh `jahebahan.tscn`, `airbahan.tscn`, dll.

### B. Decoupled Combat System (`DamageArea` & `Hitbox`)
* `DamageArea` (Area2D, bitmask `HITBOX_MASK = 3`): Mengirimkan damage saat mengenai area musuh.
* `Hitbox` (Area2D, layer `HITBOX_LAYER = 3`): Menerima sinyal damage dan meneruskannya ke `ResourceLife`.
* **Sistem Tim (`ResourceDamageTeam`):** Menentukan apakah target adalah sekutu (`is_ally`), musuh, atau friendly-fire.

### C. Kamera Sel Grid (`CameraGrid`)
* Mengadopsi pergerakan kamera gaya The Legend of Zelda 2D.
* Ukuran sel grid default: `grid_size = Vector2(320, 176)`.
* Ketika pemain bergerak keluar dari batas sel, kamera melakukan animasi `Tween` halus ke sel koordinat baru (`cell_target`).
* Kamera secara otomatis didaftarkan ke grup `"camera"`.

### D. Sistem Deteksi Kamera Luar Layar (`_is_position_visible_by_camera`)
* `GrassSpawner` mengambil instance kamera dari grup `"camera"`.
* Bounding box dihitung dari koordinat kamera $\pm$ setengah ukuran grid ditambah margin keamanan 40 pixel:
  ```gdscript
  var half_size = (cam.grid_size / 2.0) + Vector2(screen_margin_buffer, screen_margin_buffer)
  var screen_rect = Rect2(cam.global_position - half_size, half_size * 2.0)
  return screen_rect.has_point(pos)
  ```
* Jika sebuah titik `Marker2D` masuk dalam `screen_rect`, rumput dilarang respawn di titik tersebut guna mencegah efek rumput pop-in mendadak di pandangan pemain.

---

## 5. Keputusan Teknis yang Telah Disepakati (Agreed Decisions & Rationales)

| Keputusan Teknis | Alasan / Rationale |
|---|---|
| **Penamaan Scene Tanpa Karakter Garis Bawah (`_`)** | Permintaan eksplisit pengguna agar seluruh scene bahan baru konsisten dan bersih dari karakter `_` (contoh: `gulamerah.tscn`, `seraibahan.tscn`, `asamjawa.tscn`). File PNG asli tetap dipertahankan nama aslinya untuk menghindari rusaknya UID import. |
| **Pemisahan File `.tres` dan `.tscn` per Bahan** | Memisahkan data resource (`ResourceCollectible`) dari tampilan visual (`Collectible` scene) agar data bahan bisa digunakan ulang oleh UI toko, inventaris, dan resep tanpa perlu me-load scene fisik 2D. |
| **Rumput Hancur Hanya Saat Disentuh (Bukan Senjata)** | Permintaan game design: rumput dipanen dengan cara diinjak secara alami saat bereksplorasi, bukan ditebas dengan senjata tempur. Dibuat area khusus `PlayerTouchArea` di Layer 5. |
| **Jeda Pengambilan Item & Parabola Bounce** | Mencegah item langsung masuk inventory di milidetik yang sama saat pemain menginjak rumput. Item melompat sejauh 16–24 px dan baru aktif diambil setelah mendarat. |
| **Sistem Titik Spawn Berbasis Marker2D** | Sesuai preferensi level design pengguna, titik spawn rumput ditentukan secara presisi menggunakan kumpulan node `Marker2D` dengan kuota 80% rumput aktif dan rotasi titik kosong. |
| **Maksimal Stack 5 Buah per Item** | Memberikan batasan inventaris yang seimbang agar pemain terdorong untuk mengolah/meracik bahan ke kuali daripada menimbun tanpa batas. |
| **Durasi 30 Detik Item di Tanah** | Mencegah penumpukan objek tak terpakai di map yang dapat menurunkan performa. Jika diabaikan, item menghilang dan memicu respawn rumput baru setelah 15 detik. |

---

## 6. Standar Penulisan Kode (Coding Guidelines)

* **Penamaan File & Identitas:**
  * File GDScript: `snake_case.gd`.
  * ClassName: `PascalCase` (contoh: `class_name Collectible`).
  * File Scene Bahan Khusus: `nama_tanpa_garis_bawah.tscn` (contoh: `jahebahan.tscn`, `gulamerah.tscn`).
* **Static Typing:** Selalu sertakan tipe data pada variabel dan return type fungsi:
  ```gdscript
  func add_item(item_id: String, amount: int = 1) -> bool:
  var count: int = 0
  ```
* **Event-Driven Communication:**
  * Gunakan sinyal (`signal`) untuk komunikasi dari anak ke induk atau antar-sistem (`item_added`, `finished`, `killed`).
  * Jangan memanggil `get_parent().get_parent()` secara bertingkat; gunakan referensi eksplisit atau sinyal.
* **Penghapusan Node:**
  * Selalu gunakan `queue_free()` atau `call_deferred("queue_free")` saat menghapus node dari scene tree untuk menghindari bentrok memori fisika.
