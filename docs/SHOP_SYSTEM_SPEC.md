# Spesifikasi Teknis: Sistem Jual-Beli 2 Arah (Toko Mpok Sintaks) — Syntaxia

Dokumen ini mendokumentasikan spesifikasi teknis, aturan ekonomi, tata letak antarmuka (*UI Blueprint*), serta kontrak integrasi untuk **Shopping System 2 Arah (Beli & Jual)** pada proyek **Godot 4 (Target Desktop & Web HTML5)**.

> **Status Dokumen:** **SELESAI DIIMPLEMENTASIKAN & DIVERIFIKASI (100% PASS - 22/22 TESTS)**

---

## 1. Tujuan & Konsep Desain

* **Nama Toko:** **Mpok Sintaks**
* **Lokasi Pemicu:** Node bernama **`Toko`** pada scene [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn).
* **Peran Gameplay:**
  * Menyediakan transaksi **2 arah** (**Buy / Beli** dan **Sell / Jual**) khusus untuk **7 bahan rempah herbal** (`air`, `beras`, `serai`, `gulamerah`, `jahe`, `asamjawa`, `kencur`).
  * Menggunakan **Hardcore Economy** agar toko berfungsi sebagai **opsi pelengkap darurat** (menambal kekurangan 1 bahan yang sulit didapat atau menjual kelebihan stok yang mentok di `MAX_STACK = 5`), bukan pengganti mekanisme utama memanen tanaman liar (`Grass`).
  * **Proteksi Item Jamu:** Item hasil racikan (`wedangjahesereh`, `beraskencur`, `gepyokan`) tidak terdaftar di etalase toko sehingga tidak dapat dijual secara tidak sengaja.

---

## 2. Tabel Harga Beli & Jual (Hardcore Economy)

Penetapan harga diturunkan dari persentase *drop rate* tanaman `Grass` (`grass.gd`), kapasitas tas maksimal `MAX_STACK = 5`, serta hadiah Quest 1 sebesar **10 Koin Perak**:

| ID Bahan (`item_id`) | Nama Tampilan | *Drop Rate* Rumput | Tingkat Kelangkaan | Harga Beli (`BUY`) | Harga Jual (`SELL`) | Rasio Beli : Jual |
| :--- | :--- | :---: | :--- | :---: | :---: | :---: |
| `air` | Air | 25% | Umum (*Common*) | **6 Koin** | **1 Koin** | $6 : 1$ |
| `beras` | Beras | 25% | Umum (*Common*) | **6 Koin** | **1 Koin** | $6 : 1$ |
| `serai` | Sereh | 15% | Menengah (*Uncommon*) | **9 Koin** | **1 Koin** | $9 : 1$ |
| `gulamerah` | Gula Merah | 15% | Menengah (*Uncommon*) | **9 Koin** | **1 Koin** | $9 : 1$ |
| `jahe` | Jahe | 10% | Langka (*Rare*) | **12 Koin** | **2 Koin** | $6 : 1$ |
| `asamjawa` | Asam Jawa | 5% | Sangat Langka (*Very Rare*) | **18 Koin** | **3 Koin** | $6 : 1$ |
| `kencur` | Kencur | 5% | Sangat Langka (*Very Rare*) | **18 Koin** | **3 Koin** | $6 : 1$ |

### Aturan Keseimbangan Ekonomi
1. **Anti-Barter Instan:** Pemain membutuhkan hasil penjualan $6$ hingga $18$ bahan umum ($1\text{ Koin/item}$) untuk membeli $1$ bahan baru.
2. **Sinergi Quest:** Hadiah Quest 1 ($10\text{ Koin}$) tidak cukup untuk memborong seluruh bahan resep sekaligus, sehingga pemain tetap terdorong menjelajah desa dan memanen `Grass`.
3. **Manajemen Kapasitas Tas:** Karena tiap bahan dibatasi maksimal $5$ unit (`MAX_STACK = 5`), pemain dapat menjual stok bahan umum yang penuh ($5/5$) agar ruang tas tetap optimal sambil mengumpulkan koin cadangan.

---

## 3. Pemetaan Aset & Tata Letak UI (`res://content/ui/shop_ui/`)

Antarmuka `ShopUI` (`res://system/ui/shop_ui.tscn` & `shop_ui.gd`) disusun mengacu pada referensi tata letak *Questwood Pixel UI* dengan **penyesuaian khusus** untuk **Syntaxia**:

### A. Elemen Referensi yang Dihilangkan / Diganti
1. **Dihapus:** Bar nyawa (ikon hati / bar merah) dan bar air (ikon tetesan / bar biru) di bagian atas **tidak dibuat** karena status karakter sudah ditangani oleh HUD utama (`player_ui.tscn`).
2. **Diganti:** Deretan 5 tab atas (`PACK`, `SHOP`, `TALK`, `SETUP`, `HUD`) **dihapus** dan diganti menjadi **2 Tab Mode** saja: **`BUY`** dan **`SELL`**.
3. **Dipertahankan:** Indikator jumlah **Koin Perak** di pojok kanan atas yang tersinkronisasi *real-time* dengan `QuestManager.gold`.

### B. Daftar Aset & Peruntukan Komponen
Seluruh aset berada di folder `res://content/ui/shop_ui/` dan wajib dirender dengan `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` agar piksel tetap tajam:

| Nama Aset di `res://content/ui/shop_ui/` | Komponen / Peruntukan pada `ShopUI` |
| :--- | :--- |
| `shop_name` | Banner/plakat identitas toko di bagian atas yang menampilkan teks **`"Mpok Sintaks"`**. |
| `tab_normal`, `tab_hover`, `tab_pressed` | Dua tombol tab (`TextureButton`) di atas panel kiri untuk berpindah antara mode **`BUY`** (Beli) dan **`SELL`** (Jual). Tab yang sedang aktif mempertahankan visual `tab_pressed` / sorotan aktif. |
| `shop_ui_left` | Bingkai jendela utama sisi kiri. Plakat judul atas bertuliskan **`"Shop"`** (menggantikan `"TRAVEL SHOP"`). Di dalamnya terdapat grid 3 kolom (`GridContainer` dengan `columns = 3`) yang menampung 7 kartu bahan (`shop_item_card`). |
| `shop_item_card` | Kartu item individual di dalam `shop_ui_left`. Menampilkan bingkai slot di bagian atas, ikon rempah di tengah slot, serta label harga (`6 G`, `9 G`, `12 G`, `18 G` pada tab `BUY`; `1 G`, `2 G`, `3 G` pada tab `SELL`) di bagian bawah kartu. |
| `slot_selected` | Bingkai slot bertepi emas untuk menandai **item yang sedang dipilih** (baik pada kartu aktif di `shop_ui_left` maupun pada pratinjau besar di `shop_ui_right`). |
| `slot_normal` | Bingkai slot standar untuk menandai **item yang tidak sedang dipilih** (ketika tersedia). |
| `slot_empty_locked` | Bingkai slot terkunci/kosong yang digunakan **khusus pada tab `SELL`** untuk menandai item yang stoknya `0` di `PlayerInventory`. |
| `shop_ui_right` | Bingkai panel detail sisi kanan yang terbagi menjadi **2 bagian (Atas & Bawah)**:<br>• **Bagian Atas (Plakat Header):** Menampilkan **nama item yang dipilih** dari `shop_ui_left` (misal: `"JAHE"`, `"GULA MERAH"`).<br>• **Bagian Bawah (Badan Perkamen):** Menampilkan **gambar/ikon besar item** di dalam bingkai slot, informasi **stok tas (`Stok: X/5`)** & **harga transaksi**, tombol aksi **`BUY` / `SELL`**, dan tombol **`BACK`**. |
| `button_normal`, `button_hover`, `button_pressed` | Tekstur untuk dua tombol `TextureButton` di bagian bawah `shop_ui_right`:<br>1. **Tombol Aksi Utama:** Label dinamis **`"BUY"`** (saat di tab `BUY`) atau **`"SELL"`** (saat di tab `SELL`).<br>2. **Tombol Keluar:** Label **`"BACK"`** untuk menutup jendela toko. |

---

## 4. Logika & Alur Interaksi

### A. Interaksi Node `Toko` di `map_village.tscn`
* Node **`Toko`** di [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn) dilengkapi script interaksi (`res://content/character/NPC/toko_interaction.gd` atau `res://content/environment/toko_interaction.gd`) yang menyamakan pola kerja [`nara_interaction.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/character/NPC/nara_interaction.gd):
  1. Mendeteksi pemain pada Physics Layer 5 / grup `"player"` saat memasuki area interaksi (`Area2D`).
  2. Ketika pemain menekan tombol interaksi (**E**), membuka antarmuka `ShopUI`.
  3. Memanggil `_freeze_player(true)` selama `ShopUI` terbuka agar input WASD tidak menggerakkan karakter di latar belakang.
  4. Ketika tombol **`BACK`** (atau tombol `ESC`) ditekan, `ShopUI` ditutup dan `_freeze_player(false)` dipanggil untuk mengembalikan kendali pemain.

### B. State Mesin Tab `BUY` vs `SELL`
1. **Saat Toko Dibuka:**
   * Mode default adalah **`BUY`**.
   * Item pertama pada daftar (`air`) otomatis terpilih secara default agar `shop_ui_right` langsung terisi penuh tanpa tampilan kosong.
2. **Perilaku di Tab `BUY` (Beli Item):**
   * Semua kartu menampilkan harga beli (`6 G` – `18 G`).
   * Kartu item terpilih memakai `slot_selected`; kartu lainnya memakai `slot_normal`.
   * Teks tombol utama pada `shop_ui_right` berubah menjadi **`"BUY"`**.
   * **Validasi Pembelian:**
     * Jika `QuestManager.gold < buy_price` $\rightarrow$ tombol **`BUY`** dinonaktifkan (`disabled = true`) dan menampilkan keterangan koin tidak cukup.
     * Jika `current_stock >= PlayerInventory.MAX_STACK` ($5$) $\rightarrow$ tombol **`BUY`** dinonaktifkan (`disabled = true`) dan menampilkan keterangan tas penuh (`5/5`).
     * Jika valid $\rightarrow$ kurangi koin via `QuestManager.spend_gold(buy_price)`, tambah $+1$ item ke `PlayerInventory`, lalu perbarui tampilan kartu, saldo koin, dan detail kanan secara instan.
3. **Perilaku di Tab `SELL` (Jual Item):**
   * Semua kartu menampilkan harga jual (`1 G` – `3 G`).
   * **Status Slot Kartu:**
     * Jika `current_stock == 0` $\rightarrow$ kartu memakai bingkai **`slot_empty_locked`** untuk menandai item tidak tersedia di tas pemain.
     * Jika `current_stock > 0` dan kartu sedang dipilih $\rightarrow$ memakai **`slot_selected`**.
     * Jika `current_stock > 0` dan tidak dipilih $\rightarrow$ memakai **`slot_normal`**.
   * Teks tombol utama pada `shop_ui_right` berubah menjadi **`"SELL"`**.
   * **Validasi Penjualan:**
     * Jika `current_stock <= 0` $\rightarrow$ bingkai pratinjau kanan memakai `slot_empty_locked` dan tombol **`SELL`** dinonaktifkan (`disabled = true`).
     * Jika `current_stock > 0` $\rightarrow$ kurangi $1$ item dari `PlayerInventory`, tambahkan koin via `QuestManager.add_gold(sell_price)`, lalu perbarui tampilan UI secara instan.

---

## 5. Kontrak Integrasi File

1. **[`res://system/quest/quest_manager.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/quest/quest_manager.gd) (Modifikasi):**
   * Menambahkan konstanta `ITEM_PRICES: Dictionary` berisi harga beli & jual untuk 7 bahan herbal.
   * Menambahkan fungsi `get_shop_item_ids() -> Array[String]`, `get_item_buy_price(item_id: String) -> int`, `get_item_sell_price(item_id: String) -> int`, dan `spend_gold(amount: int) -> bool` (memancarkan sinyal `gold_changed`).
2. **[`res://system/ui/shop_ui.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/shop_ui.tscn) & [`res://system/ui/shop_ui.gd`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/system/ui/shop_ui.gd) (Baru):**
   * Antarmuka modal toko 2 arah lengkap dengan tab `BUY`/`SELL`, grid 3 kolom `shop_item_card`, panel detail `shop_ui_right`, pembaruan stok *real-time*, dan pembekuan kontrol pemain (`_freeze_player`).
3. **Script Interaksi pada Node `Toko` di [`res://content/map/map_village.tscn`](file:///e:/GAME%20ENGINE/Game%20Project/Syntaxia/content/map/map_village.tscn) (Baru & Terpasang):**
   * Menghubungkan node `Toko` dengan tombol interaksi **E** seperti interaksi NPC quest (`nara_interaction.gd`) untuk memunculkan `ShopUI`.