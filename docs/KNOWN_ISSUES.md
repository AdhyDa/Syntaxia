# KNOWN ISSUES & TROUBLESHOOTING LOG — SYNTAXIA

Dokumen ini mencatat daftar kendala teknis, error yang pernah terjadi selama pengembangan sistem Collectible & Spawner, solusi yang berhasil/gagal, serta bagian arsitektur yang berpotensi menimbulkan masalah di masa mendatang (*risk areas*).

---

## 1. Error yang Pernah Terjadi & Solusinya

### A. Broken Path pada `@icon` Annotations di GDScript
* **Deskripsi Masalah:**
  Saat file [`grass.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/grass.gd) dan [`collectible.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/collectible/collectible.gd) dibuka, Godot Engine mengeluarkan error:
  `Failed loading resource: res://content/collectible/destroyable/icon_destroyable.png`
* **Penyebab:**
  Script `grass.gd` dipindahkan ke subfolder `content/collectible/bahan/`, tetapi path `@icon` masih menggunakan path relatif `../destroyable/icon_destroyable.png`. Sementara pada `collectible.gd`, file `icon_collectible.png` memang belum ada.
* **Solusi yang Gagal:**
  Membiarkan path relatif lama menyebabkan editor terus memunculkan error setiap kali filesystem di-scan.
* **Solusi yang Berhasil:**
  1. Pada `grass.gd`, path diubah menjadi path absolut: `@icon("res://system/destroyable/icon_destroyable.png")`.
  2. Pada `collectible.gd`, baris `@icon` dihapus karena ikon kustom belum dibuat.

---

### B. File Resource 0-Byte Akibat Crash / Disconnect
* **Deskripsi Masalah:**
  File [`serai.tres`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/collectible/bahan/serai.tres) berukuran 0 bytes, menyebabkan engine gagal me-load resource collectible untuk bahan serai.
* **Penyebab:**
  Proses penulisan file terinterupsi saat engine atau tool melakukan auto-reload secara bersamaan.
* **Solusi yang Berhasil:**
  File ditulis ulang secara manual menggunakan struktur text resource Godot (`ResourceFormatText`) yang valid:
  ```tres
  [gd_resource type="Resource" script_class="ResourceCollectible" load_steps=3 format=3]
  [ext_resource type="Script" path="res://system/collectible/resource_collectible.gd" id="1_script"]
  [ext_resource type="Texture2D" path="res://content/collectible/bahan/serai.png" id="2_icon"]
  [resource]
  script = ExtResource("1_script")
  item_id = "serai"
  display_name = "Serai"
  icon = ExtResource("2_icon")
  ```

---

### C. Redundansi & Kerentanan Node Marker2D pada Scene Map
* **Deskripsi Masalah:**
  Pengguna merasa bingung dan kesulitan saat ingin menambah, menghapus, atau memindahkan posisi titik spawn rumput. Saat fitur *Editable Children* dinonaktifkan di `map_village.tscn`, child node `Markers` hilang namun `Marker1` sampai `Marker10` tetap muncul sebagai direct children yang berantakan di Scene Tree.
* **Penyebab:**
  Ketidaksesuaian hierarki antara scene dasar `grass_spawner.tscn` (yang memiliki container node `Markers`) dengan scene peta `map_village.tscn` (yang menaruh marker langsung di bawah instansiasi spawner).
* **Solusi yang Gagal:**
  Menginstruksikan pengguna untuk mengaktifkan/menonaktifkan *Editable Children* secara manual di editor. Hal ini rawan error, merusak hierarki scene Godot, dan tidak praktis saat map diperluas.
* **Solusi yang Berhasil:**
  Arsitektur spawn dirombak total dari sistem **Diskrit (Marker2D)** menjadi sistem **Kontinu (Spawn Zone)**:
  1. `grass_spawner.gd` kini membaca area persegi (`zone_size` dan `zone_offset`).
  2. Menggunakan anotasi `@tool` dan fungsi `_draw()` sehingga batas area spawn tergambar otomatis di Editor Viewport sebagai kotak hijau transparan.
  3. Seluruh 10 node `Marker2D` dihapus dari `map_village.tscn`. Scene Tree kini bersih, dan pengguna cukup memindahkan 1 node `GrassSpawner` atau mengubah `zone_size` di panel Inspector.

---

### D. Eksekusi Godot CLI Headless pada Windows Environment
* **Deskripsi Masalah:**
  Perintah `godot --headless` atau `godot.exe` gagal dieksekusi di terminal PowerShell lokal dengan pesan `CommandNotFoundException`.
* **Penyebab:**
  Binary Godot Engine tidak terdaftar di dalam System Environment `PATH` Windows.
* **Solusi yang Berhasil:**
  Menggunakan integrasi MCP Server `godot-ai` resmi yang berkomunikasi langsung dengan Godot Engine Editor yang sedang berjalan (`project_run`, `logs_read`, `filesystem_manage`, `scene_open`, dll).

---

## 2. Bagian yang Berpotensi Menimbulkan Masalah (*Risk Areas*)

1. **Camera Grid vs Viewport Size:**
   * Di dalam [`grass_spawner.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/spawner/grass_spawner.gd), fungsi `_is_position_visible_by_camera()` mencoba membaca properti `grid_size` pada node kamera yang berada di grup `"camera"`.
   * *Risiko:* Jika pemain mengganti kamera atau kamera tidak memiliki properti `grid_size`, sistem melakukan fallback ke `get_viewport().get_visible_rect().size / cam.zoom`. Jika node kamera belum terdaftar di grup `"camera"`, fungsi akan mengembalikan `false` (menganggap posisi tidak terlihat kamera).
   * *Rekomendasi:* Pastikan kamera utama selalu berada di grup `"camera"`.

2. **Integrasi Dummy UI pada Resep & Quest:**
   * File [`recipe_scroll.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recipe_scroll.gd) dan [`recent_quest.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/recent_quest.gd) saat ini masih meng-hardcode teks kuantitas bahan ("0/1").
   * *Risiko:* Belum ada koneksi dinamis ke autoload `PlayerInventory`. Pemain yang memungut bahan di lapangan belum melihat angkanya berubah di dalam menu gulungan resep.
   * *Rekomendasi:* Sambungkan sinyal `PlayerInventory.inventory_changed` ke UI resep.

3. **Collision Obstacle pada Spawn Zone:**
   * Algoritma `_find_valid_spawn_position()` saat ini melakukan uniform random sampling di dalam `Rect2`.
   * *Risiko:* Jika zona spawn diperbesar hingga menabrak bangunan rumah desa atau pohon besar yang memiliki collision solid, ada peluang kecil rumput muncul di atas atap rumah atau menembus dinding penghalang.
   * *Rekomendasi:* Jika zona diperluas, tambahkan pemeriksaan `PhysicsServer2D` raycast/point intersection untuk memastikan titik acak tidak berada di dalam layer collider dinding/bangunan desa.
