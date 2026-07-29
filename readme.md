# DSpace 10 Docker Setup (Sesuai Dokumentasi Resmi & Nginx Reverse Proxy)

Setup repository ini dibangun sepenuhnya berdasarkan **[Dokumentasi Resmi DSpace 10 Docker (LYRASIS Wiki)](https://wiki.lyrasis.org/spaces/DSPACE/pages/425331100/Try+out+DSpace+10#TryoutDSpace10-InstallviaDocker)** dan diperkaya dengan **Nginx Reverse Proxy** untuk memudahkan akses domain tunggal (misal `http://localhost` atau `https://repository.univ.ac.id`).

---

## 🏗️ Arsitektur Sistem

Seluruh service menggunakan image resmi DSpace 10:

| Service | Container Name | Fungsi | Akses Direct |
|---|---|---|---|
| `dspace-nginx` | `dspace-nginx` | Reverse proxy utama (pintu masuk port 80) | `http://localhost` |
| `dspace-angular` | `dspace-angular` | Frontend User Interface (Angular SSR) | `http://localhost:4000` |
| `dspace` | `dspace` | Backend REST API | `http://localhost:8080/server` |
| `dspacedb` | `dspacedb` | PostgreSQL 15 database | Internal network |
| `dspacesolr` | `dspacesolr` | Solr 8 Search & Analytics Engine | `http://localhost:8983/solr` |

---

## 🌐 Akses Pintu Masuk Satu Domain

Dengan Nginx Reverse Proxy:
- **Frontend UI**: `http://localhost/` (Routing otomatis ke container UI)
- **Backend REST API**: `http://localhost/server/` (Routing otomatis ke REST API)

---

## 🚀 Cara Menjalankan DSpace 10

### 1. Pull Image & Build
Jalankan perintah resmi DSpace 10 Docker Compose:

```bash
docker compose -p d10 -f docker/docker-compose-dist.yml -f docker/docker-compose-rest.yml -f docker-compose.override.yml pull
```

### 2. Jalankan Stack
```bash
docker compose -p d10 -f docker/docker-compose-dist.yml -f docker/docker-compose-rest.yml -f docker-compose.override.yml up -d
```
> Atau cukup gunakan perintah singkat:
> ```bash
> docker compose up -d
> ```

### 3. Cek Log Sistem / Monitoring Startup
DSpace backend membutuhkan waktu 1–3 menit untuk inisialisasi database & Solr cores saat pertama kali dijalankan:

```bash
docker compose -p d10 -f docker/docker-compose-dist.yml -f docker/docker-compose-rest.yml logs -f
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

## 🔧 Pengaturan Custom Domain Produksi (`repository.univ.ac.id`)

Jika ingin menyebar ke domain kampus / produksi:

1. Buka file `docker-compose.override.yml` atau set Environment Variable di server:
   ```yaml
   dspace:
     environment:
       dspace__P__server__P__url: http://repository.univ.ac.id/server
       dspace__P__ui__P__url: http://repository.univ.ac.id

   dspace-angular:
     environment:
       DSPACE_UI_HOST: repository.univ.ac.id
       DSPACE_UI_BASEURL: http://repository.univ.ac.id
       DSPACE_REST_HOST: repository.univ.ac.id
       DSPACE_REST_BASEURL: http://repository.univ.ac.id/server
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
docker compose -p d10 -f docker/docker-compose-dist.yml -f docker/docker-compose-rest.yml -f docker-compose.override.yml down
```

Untuk menghentikan dan **menghapus seluruh volume data** (reset bersih):
```bash
docker compose -p d10 -f docker/docker-compose-dist.yml -f docker/docker-compose-rest.yml -f docker-compose.override.yml down -v
```