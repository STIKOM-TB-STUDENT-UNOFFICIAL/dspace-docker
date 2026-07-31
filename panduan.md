# 📖 Panduan Penggunaan DSpace 10 Docker

Dokumen ini berisi panduan lengkap penggunaan **DSpace 10** dari sisi pengelolaan server (Docker CLI) hingga manajemen repositori institusi melalui antarmuka web (Administrator UI).

---

## 🏛️ 1. Memahami Struktur Hierarki DSpace

DSpace menggunakan struktur hierarki untuk mengorganisir dokumen institusi/kampus:

```text
📁 Community (Top-Level)         --> Contoh: Fakultas Ilmu Komputer
  ├── 📁 Sub-Community          --> Contoh: Program Studi Teknik Informatika
  │     ├── 📂 Collection       --> Contoh: Skripsi & Tugas Akhir TI
  │     │     ├── 📄 Item       --> Contoh: Judul Skripsi "Sistem Pakar..."
  │     │     │     └── 📑 File --> Contoh: Jurnal.pdf / Skripsi.pdf
  │     │     └── 📄 Item
  │     └── 📂 Collection       --> Contoh: Jurnal Dosen TI
  └── 📁 Sub-Community
```

---

## 📧 2. Konfigurasi SMTP Email (`.env`)

DSpace menggunakan variabel di file `.env` untuk mengatur pengiriman email, notifikasi registrasi, reset password, dan persetujuan workflow.

### Cara Mengatur SMTP via `.env`:
1. Buka file `.env` di direktori proyek (`nano .env` atau `code .env`).
2. Sesuaikan opsi email berikut:

```env
# Set ke false HANYA JIKA username & password SMTP sudah diisi
SMTP_DISABLED=false

# Host & Port SMTP (Contoh Gmail):
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=emailanda@gmail.com
SMTP_PASS=password_atau_app_password_anda

# Header Email Pengirim & Administrator
SMTP_FROM_ADDRESS=noreply@repository.stikomtunasbangsa.ac.id
SMTP_FEEDBACK_RECIPIENT=admin@repository.stikomtunasbangsa.ac.id
SMTP_ADMIN_EMAIL=admin@repository.stikomtunasbangsa.ac.id
```

> 💡 **Catatan untuk Gmail**: Jika menggunakan Gmail, Anda **wajib** menggunakan **Google App Password 16 Karakter** (dibuat di *Google Account -> Security -> 2-Step Verification -> App Passwords*).

3. Simpan file `.env` lalu terapkan perubahan dengan:
   ```bash
   docker compose up -d
   ```

---

## 🖥️ 3. Panduan Operasional Server (Perintah CLI)

Semua perintah dijalankan di terminal server pada direktori `dspace-docker`:

### 🚀 Mengoperasikan Container DSpace
| Tujuan | Perintah |
|---|---|
| Menjalankan DSpace | `docker compose up -d` |
| Menghentikan DSpace | `docker compose down` |
| Merestart DSpace | `./restart.sh` atau `docker compose restart` |
| Reset & Migrasi Ulang Database | `./reset-db.sh` |
| Factory Reset Total (Clean Install) | `./factory-reset.sh` |
| Melihat Log Backend/Nginx | `docker compose logs -f` |

### 👤 Membuat Akun Administrator (EPerson)
Untuk membuat akun Admin baru:
```bash
./create-admin.sh
```
> *Atau dengan kredensial kustom:*
> ```bash
> ./create-admin.sh email@kampus.ac.id NamaDepan NamaBelakang Password123
> ```

### 📦 Mengimpor Data Sampel (AIP Ingest)
Untuk mengisi repositori dengan contoh Komunitas, Koleksi, dan Dokumentasi tes:
```bash
./sample-ingest.sh
```

### 🎨 Rebuild UI Custom (Jika Mengubah Kode Tema UI)
```bash
./rebuild-frontend.sh
```

### 💾 Backup & Restore
- **Backup**: `./backup.sh` *(Hasil backup tersimpan di `./backup/YYYYMMDD_HHMMSS/`)*
- **Restore**: `./restore.sh ./backup/FOLDER_BACKUP`

---

## 🌐 3. Panduan Penggunaan Administrator di Web UI

Akses URL Repositori: **`https://repository.stikomtunasbangsa.ac.id/`**

### 🔑 A. Pertama Kali Login (End User Agreement)
1. Klik **Log In** di pojok kanan atas UI.
2. Masukkan Email dan Password Admin yang telah dibuat.
3. Saat muncul halaman **End User Agreement**, centang **`☑ I have read and I agree...`** lalu klik **Save** di pojok kanan bawah.

---

### 📂 B. Membuat Community & Collection Pertama

1. **Membuat Community (Fakultas)**:
   - Login sebagai Admin.
   - Klik tombol **`+ New`** di menu atas atau sidebar kiri -> pilih **`Community`**.
   - Isi judul (misal: *Fakultas Teknologi Informasi*) dan deskripsi.
   - Klik **Save**.

2. **Membuat Collection (Skripsi / Jurnal)**:
   - Buka Community yang baru dibuat.
   - Klik **`+ New`** -> pilih **`Collection`**.
   - Isi nama koleksi (misal: *Skripsi Teknik Informatika 2026*).
   - Klik **Save**.

---

### 📄 C. Mengunggah / Upload Dokumen (Submit Item)

1. Klik tombol **`+ New`** -> pilih **`Item`**.
2. Pilih **Collection** tujuan dokumen akan disimpan.
3. **Mengisi Metadata**:
   - **Title**: Judul penelitian / dokumen.
   - **Author**: Nama pengarang / mahasiswa.
   - **Date**: Tanggal terbit.
   - **Subject / Keywords**: Kata kunci pencarian.
   - **Abstract**: Ringkasan / abstrak dokumen.
4. **Mengunggah File**:
   - Drag & drop file PDF ke area upload.
   - Tentukan nama file & deskripsi (misal: *File Utama PDF*).
5. Klik **Deposit** untuk mempublikasikan item secara instan ke repositori.

---

### 👥 D. Manajemen User (EPerson) & Grup Hak Akses

1. Buka menu Admin (Ikon Kunci / *Access Control* di sidebar kiri).
2. **EPeople**:
   - Untuk menambah user baru, edit nama, atau mengubah password.
3. **Groups**:
   - **Administrator**: User yang berada di grup ini memiliki akses kontrol penuh.
   - **Submitter**: Grup user yang diizinkan mengunggah dokumen ke koleksi tertentu.
   - **Workflow Groups**: Grup peninjau (*Reviewer/Editor*) yang bertugas menyetujui/menolak unggahan sebelum dipublikasikan.

---

## 🛠️ 4. Troubleshooting & Solusi Kendala

| Kendala | Penyebab | Solusi |
|---|---|---|
| **Persetujuan Agreement Tidak Bisa Disimpan** | Cache browser atau Mixed Content SSL | Buka mode *Incognito*, lalu centang dan tekan **Save**. |
| **Port Nginx / Database Bentrok** | Port 80 atau 5432 sudah terpakai service lain di server | Edit file `.env`, ubah `NGINX_HOST_PORT=8081` atau `DB_HOST_PORT=5431`, lalu `docker compose up -d`. |
| **Halaman Putih Saat Refresh Sub-rute** | Cache Nginx belum me-reload rute Angular | Jalankan `./restart.sh` di server Linux. |
| **403 Forbidden saat Tambah/Hapus di Konfigurasi** | Reverse proxy kampus tidak dipercaya DSpace | Lihat panduan lengkap di bawah. |

---

## 🚨 5. Fix: Error 403 di Menu Konfigurasi (Server Kampus)

### Gejala
- Login berhasil ✅
- Browsing konten berhasil ✅
- Operasi **Tambah / Hapus / Edit** di menu konfigurasi **GAGAL dengan 403** ❌
- Refresh halaman menampilkan **403 Forbidden** ❌

### Penyebab
Saat di-deploy di server kampus, biasanya ada **reverse proxy eksternal** (Nginx/Apache kampus atau Cloudflare) di depan container Docker.

DSpace backend hanya mempercayai request dari IP range tertentu (`proxies.trusted.ipranges`). Request `POST`/`DELETE` (operasi tulis) dari IP reverse proxy kampus dianggap **tidak trusted** → **403 Forbidden**.

### Langkah Perbaikan

#### Langkah 1: Cari tahu IP subnet Docker gateway di server kampus

SSH ke server kampus, lalu jalankan:

```bash
# Cek IP bridge Docker yang dipakai container dspace
docker network inspect $(docker network ls | grep dspacenet | awk '{print $1}') | grep -E '"Subnet"|"Gateway"'
```

> Contoh output:
> ```
> "Subnet": "172.23.0.0/16",
> "Gateway": "172.23.0.1"
> ```

```bash
# Cek IP server host (IP yang digunakan oleh Nginx kampus)
hostname -I
```

#### Langkah 2: Edit file `.env` di server kampus

Tambahkan/ubah variabel `PROXIES_TRUSTED_IPRANGES`:

```env
# Tambahkan semua IP range yang relevan, pisahkan dengan koma
# Format: 3 oktet pertama dari IP (tanpa .0 di akhir)
# Contoh di bawah: Docker subnet + IP privat server kampus
PROXIES_TRUSTED_IPRANGES=172.23.0,10.0.0,192.168.1
```

> **Catatan**:
> - `172.23.0` = subnet internal Docker (wajib ada)
> - `10.0.0` atau `192.168.1` = IP internal server kampus (sesuaikan!)
> - Jangan gunakan `0.0.0.0` — terlalu luas dan tidak aman

#### Langkah 3: Restart container

```bash
docker compose up -d
```

#### Langkah 4: Verifikasi

Buka browser, login sebagai Admin, coba Tambah/Hapus di menu konfigurasi. Jika masih 403, cek log backend:

```bash
docker logs dspace --tail=50 | grep -i "403\|forbidden\|proxy\|trusted"
```

---
