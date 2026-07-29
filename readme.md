# DSpace 10 Docker Setup (Sesuai Dokumentasi Resmi & Nginx Reverse Proxy)

Setup repository ini dibangun sepenuhnya berdasarkan **[Dokumentasi Resmi DSpace 10 Docker (LYRASIS Wiki)](https://wiki.lyrasis.org/spaces/DSPACE/pages/425331100/Try+out+DSpace+10#TryoutDSpace10-InstallviaDocker)** dan diperkaya dengan **Nginx Reverse Proxy** untuk memudahkan akses domain tunggal (misal `http://localhost` atau `https://repository.univ.ac.id`).

---

## 🏗️ Arsitektur Sistem

Seluruh service menggunakan image resmi DSpace 10:

| Service | Container Name | Fungsi | Akses Direct / Port Host |
|---|---|---|---|
| `dspace-nginx` | `dspace-nginx` | Reverse proxy utama (pintu masuk port 80/custom) | `http://localhost:${NGINX_HOST_PORT:-80}` |
| `dspace-angular` | `dspace-angular` | Frontend User Interface (Angular SSR) | `http://localhost:4000` |
| `dspace` | `dspace` | Backend REST API | `http://localhost:8080/server` |
| `dspacedb` | `dspacedb` | PostgreSQL 15 database | `localhost:${DB_HOST_PORT:-5431}` |
| `dspacesolr` | `dspacesolr` | Solr 8 Search & Analytics Engine | `http://localhost:8983/solr` |

---

## 🌐 Akses Pintu Masuk Satu Domain

Dengan Nginx Reverse Proxy:
- **Frontend UI**: `http://localhost:${NGINX_HOST_PORT}/` (Routing otomatis ke container UI)
- **Backend REST API**: `http://localhost:${NGINX_HOST_PORT}/server/` (Routing otomatis ke REST API)

---

## 🚀 Cara Menjalankan DSpace 10

### 1. Salin `.env` (Jika belum ada)
```bash
cp .env.example .env
```

### 2. Hapus folder nginx.conf lama yang terbuat otomatis (Jika muncul error mount)
Jika sebelumnya pernah mengalami error OCI mount karena Docker membuat folder `docker/nginx.conf`, bersihkan dulu dengan:
```bash
rm -rf docker/nginx.conf
```

### 3. Pull & Jalankan Stack
Jalankan perintah Docker Compose standar di root direktori proyek:

```bash
docker compose up -d
```

### 4. Cek Log Sistem / Monitoring Startup
DSpace backend membutuhkan waktu 1–3 menit untuk inisialisasi database & Solr cores saat pertama kali dijalankan:

```bash
docker compose logs -f
```

---

## 👤 Membuat Akun Administrator (EPerson)

Setelah container running, buat akun Administrator awal dengan script bantuan:

```bash
./create-admin.sh
```
*Default akun yang dibuat:*
- Email: `test@test.edu`
- Password: `admin`
- First Name: `admin`
- Last Name: `user`

> *Atau tentukan kredensial sendiri:*
> ```bash
> ./create-admin.sh admin@univ.ac.id NamaDepan NamaBelakang Password123
> ```

---

## 📦 Mengisi Data Sample / Test Data (AIP Ingest)

Untuk menguji fitur DSpace 10 dengan data awal (komunitas, koleksi, dan item sampel):

```bash
./sample-ingest.sh
```

---

## 🎨 Menggunakan Custom Frontend UI Repository

Jika Anda menggunakan **repository Angular UI kustom** (misal hasil modifikasi tema/layout sendiri di GitHub):

1. Buka file `.env` dan atur URL repository serta branch custom Anda:
   ```env
   FRONTEND_REPO=https://github.com/USERNAME/custom-dspace-angular.git
   FRONTEND_BRANCH=main
   ```
2. Build dan jalankan ulang container UI dengan script bantuan:
   ```bash
   ./rebuild-frontend.sh
   ```

---

## 🔧 Pengaturan Port & Custom Domain Produksi (`repository.univ.ac.id`)

Jika port `80` di server sudah digunakan webserver lain (misal Apache / Nginx bawaan server):

1. Edit file `.env` dan ganti `NGINX_HOST_PORT` ke port lain (misal `8081`):
   ```env
   # Port Nginx yang diexpose ke server host
   NGINX_HOST_PORT=8081

   # Jika menggunakan port kustom (misal 8081):
   DSPACE_SERVER_URL=http://repository.univ.ac.id:8081/server
   DSPACE_UI_URL=http://repository.univ.ac.id:8081
   DSPACE_UI_HOST=repository.univ.ac.id
   DSPACE_REST_HOST=repository.univ.ac.id
   DSPACE_UI_PORT=8081
   DSPACE_REST_PORT=8081
   ```
2. Restart container:
   ```bash
   docker compose up -d
   ```

---

## 💾 Backup & Restore Data

### Backup
Membuat salinan cadangan database (`pg_dump`), Solr index, dan file bitstream (`assetstore`):

```bash
./backup.sh
```
File backup akan disimpan di `./backup/YYYYMMDD_HHMMSS/`.

### Restore
Mengembalikan data dari folder backup:

```bash
./restore.sh ./backup/20260729_120000
```

---

## 🛑 Menghentikan DSpace

Untuk menghentikan container sementara:
```bash
docker compose down
```

Untuk menghentikan dan **menghapus seluruh volume data** (reset bersih):
```bash
docker compose down -v
```