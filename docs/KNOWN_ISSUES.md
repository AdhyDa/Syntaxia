# KNOWN ISSUES & TROUBLESHOOTING LOG — SYNTAXIA

Dokumen ini mencatat daftar kendala teknis, error yang pernah terjadi selama pengembangan sistem, solusi yang berhasil/gagal, serta bagian arsitektur yang berpotensi menimbulkan masalah di masa mendatang (*risk areas*).

---

## 1. Error yang Pernah Terjadi & Solusinya

### A. Broken Path pada `@icon` Annotations di GDScript
* **Deskripsi Masalah:**
  Saat file `grass.gd` dan `collectible.gd` dibuka, Godot Engine mengeluarkan error `Failed loading resource`.
* **Penyebab:** Script dipindahkan ke subfolder baru, tetapi path `@icon` masih menggunakan path relatif lama.
* **Solusi yang Berhasil:** Mengubah path menjadi path absolut proyek: `@icon("res://system/destroyable/icon_destroyable.png")`.

---

### B. File Resource 0-Byte Akibat Crash / Disconnect
* **Deskripsi Masalah:** File `serai.tres` berukuran 0 bytes menyebabkan error saat loading.
* **Penyebab:** Penulisan terinterupsi saat reload bersamaan.
* **Solusi yang Berhasil:** Menulis ulang file resource secara manual sesuai format `ResourceFormatText` Godot 4.

---

### C. Redundansi & Kerentanan Node Marker2D pada Scene Map
* **Deskripsi Masalah:** Pengguna bingung dengan hierarki 10 node `Marker2D` yang berantakan saat *Editable Children* dimatikan.
* **Solusi yang Berhasil:** Sistem disederhanakan dan distandardisasi dengan tetap mempertahankan struktur Marker2D yang rapi di bawah parent node `GrassSpawner`.

---

### D. Duplikasi Nomor Baris ("11") pada Grimoire UI
* **Deskripsi Masalah:**
  Pada layar peracikan Grimoire UI, nomor baris pertama terlihat ganda sebagai `"11"`, dan teks bayangan *ghost-text* bergeser tidak sejajar dengan teks ketikan pemain.
* **Penyebab:**
  Kedua layer `CodeEdit` (`GhostCodeEdit` di bawah dan `PlayerCodeEdit` di atas) sama-sama mengaktifkan gutter nomor baris. Akibatnya, angka `1` pada layer bawah bertumpuk dengan angka `1` pada layer atas. Selain itu, lebar gutter membuat posisi kolom teks bergeser.
* **Solusi yang Berhasil:**
  1. Menonaktifkan gutter nomor baris pada layer bayangan: `ghost_code_edit.gutters_draw_line_numbers = false`.
  2. Menggeser koordinat X `GhostCodeEdit` ke kanan sebesar lebar gutter `PlayerCodeEdit`:
     ```gdscript
     var gutter_width: float = player_code_edit.get_total_gutter_width()
     ghost_code_edit.position.x = gutter_width
     ghost_code_edit.size.x = player_code_edit.size.x - gutter_width
     ```

---

### E. Karakter Pemain Tetap Bergerak Saat Dialog / Modal UI Terbuka
* **Deskripsi Masalah:**
  Saat pemain sedang berbicara dengan NPC Nara, meracik di kuali, atau membuka jendela List Quest, menekan tombol WASD tetap membuat karakter berjalan di belakang antarmuka.
* **Penyebab:**
  Input karakter diproses oleh `HumanController` tanpa memeriksa apakah antarmuka modal sedang aktif. Pemanggilan `find_child("HumanController")` sebelumnya gagal karena node controller dibuat via kode tanpa diberi nama properti eksplisit `name = "HumanController"`.
* **Solusi yang Berhasil:**
  1. Di `player_assignor.gd`, menyetel `human_controller.name = "HumanController"`.
  2. Di seluruh modul modal UI (`nara_dialog_ui.gd`, `grimoire_ui.gd`, `quest_detail_popup.gd`), mengimplementasikan fungsi pembekuan terpusat:
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

---

### F. Companion Robot Diam Tidak Mengikuti Pemain
* **Deskripsi Masalah:**
  Karakter pengikut `robot` di `map_village.tscn` tetap diam di tempat saat pemain bergerak menjauh.
* **Penyebab:**
  Node `BehaviorFollow` di dalam instance `robot` tidak memiliki konfigurasi `target`, sehingga bernilai null.
* **Solusi yang Berhasil:**
  Menambahkan target path `target = NodePath("../../player")` pada scene `map_village.tscn` serta memperkuat penanganan sinyal `teleported` di `behavior_follow.gd`.

---

### G. Error Spam Index Out of Bounds pada `sprite_character.gd`
* **Deskripsi Masalah:**
  Saat game dijalankan, konsol mengeluarkan error berulang:
  `Index p_coord.y = 1 is out of bounds (vframes = 1). (res://system/character/sprite_character.gd:53 @ update_animation)`
* **Penyebab:**
  Karakter seperti companion `robot` mewarisi `character.tscn` dengan `SpriteCharacter` yang memiliki `vframes = 1` (hanya 1 baris frame). Animasi default mencoba mengakses frame baris ke-1, 2, 3 dari `image_list`, melebihi jumlah baris sheet.
* **Solusi yang Berhasil:**
  Menambahkan validasi batas aman di `sprite_character.gd`:
  ```gdscript
  func update_animation():
      var fx = direction_to_frame(direction)
      frame_coords.x = fx if fx < hframes else 0
      if vframes > 1 and image_list.size() > 0:
          var fy = image_list[floor(current_image)]
          frame_coords.y = fy if fy < vframes else 0
      else:
          frame_coords.y = 0
  ```

---

### H. Duplikasi Kartu Quest Akibat Penundaan `queue_free()` di Frame yang Sama
* **Deskripsi Masalah:**
  Saat fungsi `refresh_details()` pada `quest_detail_popup.gd` dipanggil berulang kali di frame yang sama, jumlah kartu quest di dalam list menjadi terduplikasi (2 kartu menjadi 4 kartu).
* **Penyebab:**
  Perintah `child.queue_free()` tidak langsung menghapus node dari `get_children()` di frame berjalan, melainkan menunggunya hingga akhir frame (`idle_frame`). Jika fungsi dipanggil kembali sebelum frame berakhir, node lama masih terbaca.
* **Solusi yang Berhasil:**
  Melepaskan node terlebih dahulu dari tree menggunakan `remove_child` sebelum memanggil `queue_free`:
  ```gdscript
  for child in quest_list_container.get_children():
      quest_list_container.remove_child(child)
      child.queue_free()
  ```

---

### I. Tanda `"-"` Muncul Saat List Quest Kosong
* **Deskripsi Masalah:**
  Saat pemain belum mengambil quest apapun, jendela List Quest memunculkan tanda `"-"` yang membingungkan pemain.
* **Solusi yang Berhasil:**
  Menyembunyikan seluruh label teknis saat quest kosong dan menampilkan teks ramah tanpa karakter `"-"`:
  `"Belum ada quest yang diambil.\n\nSilakan temui warga desa untuk menerima pesanan ramuan jamu!"`

---

## 2. Bagian yang Berpotensi Menimbulkan Masalah (*Risk Areas*)

1. **Preload Cache GDScript pada Editor:**
   * Di dalam editor Godot 4, pengeditan script yang menggunakan kata kunci `@tool` terkadang mempertahankan cache versi sebelumnya hingga editor di-restart.
   * *Rekomendasi:* Selalu uji fungsionalitas gameplay di runtime engine (`project_run`) atau restart editor jika terjadi perilaku aneh pada script `@tool`.

2. **Dukungan Sintaks Resep Level Lanjutan (Level 2 & Level 3):**
   * Saat ini `RecipeParser` memiliki Quest-Lock yang menolak eksekusi jika `active_quest_id != 1`.
   * *Rekomendasi:* Saat mengimplementasikan Level 2, tambahkan fungsi `_validate_level_2()` untuk memeriksa sintaks loop `ULANGI 3 KALI` tanpa mengubah validasi Level 1 yang sudah stabil.
