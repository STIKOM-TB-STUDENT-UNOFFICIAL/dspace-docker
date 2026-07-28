# DSpace Docker Setup

Setup DSpace dengan backend official image, frontend custom (build dari repo GitHub sendiri), dan nginx sebagai reverse proxy penyatu keduanya.

## Struktur

```
.
├── docker-compose.yml
├── Dockerfile.frontend
├── nginx.conf
├── backup.sh
├── restore.sh
└── rebuild-frontend.sh
```

| Service | Fungsi |
|---|---|
| `dspacedb` | PostgreSQL — database DSpace |
| `dspacesolr` | Solr — search index & statistics |
| `dspace-backend` | REST API DSpace (image resmi, tidak dikustom) |
| `dspace-frontend` | Angular SSR — di-build dari repo custom kamu |
| `nginx` | Reverse proxy — satu pintu masuk (`http://localhost`) untuk backend + frontend |

## Menjalankan

```bash
docker compose up -d --build
```

Akses:
- Frontend: `http://localhost`
- Backend REST API: `http://localhost/server`

## Update frontend saat repo GitHub berubah

Build Docker meng-cache layer `git clone`, jadi rebuild biasa tidak otomatis ambil commit baru. Gunakan script ini:

```bash
./rebuild-frontend.sh
```

Script ini mengecek commit terbaru di remote (`git ls-remote`), lalu memaksa Docker re-clone hanya kalau ada commit baru.

Sesuaikan dulu `FRONTEND_REPO` dan `FRONTEND_BRANCH` di:
- `docker-compose.yml` (bagian `build.args`)
- `rebuild-frontend.sh`

## Backup & Restore

```bash
./backup.sh                              # buat backup baru di ./backup/<timestamp>/
./restore.sh ./backup/<timestamp>        # restore dari folder backup tertentu
```

Isi backup: dump database (`pg_dump`), volume Solr, dan volume assetstore (file bitstream asli).

Sesuaikan `PROJECT_PREFIX` di kedua script dengan nama folder project ini (cek dengan `docker volume ls`).

## Akses database lewat DB admin (Beekeeper Studio, dsb)

Secara default port PostgreSQL **tidak di-expose** ke host — koneksi antar container cukup lewat network internal.

Untuk akses dari Beekeeper/DB client di komputer yang sama, tambahkan di service `dspacedb`:

```yaml
ports:
  - "127.0.0.1:5432:5432"
```

Lalu koneksikan dengan host `localhost`, port `5432`, database `dspace`.

> Kalau server ini publik/VPS: jangan bind ke `0.0.0.0`, batasi ke `127.0.0.1` atau firewall, dan ganti kredensial default database sebelum production.

## Menambahkan user (e-person) DSpace

User di DSpace disebut **e-person**. Ada dua cara utama menambahkannya, tanpa perlu menyentuh setup admin:

### 1. Lewat CLI (di dalam container backend)

```bash
docker exec -it dspace-backend /dspace/bin/dspace create-eperson \
  -e <email_user> \
  -f <nama_depan> \
  -l <nama_belakang> \
  -c \
  -m
```

Keterangan flag:
- `-e` email user (dipakai untuk login)
- `-f` / `-l` nama depan / belakang
- `-c` user akan diminta set password sendiri saat login pertama
- `-m` kirim email notifikasi (butuh SMTP dikonfigurasi; kalau belum ada SMTP, hilangkan flag ini dan set password manual lewat opsi `-p <password>`)

### 2. Lewat UI Admin

Kalau sudah ada 1 akun admin, user baru juga bisa ditambahkan lewat:
`http://localhost/access-control/epeople` → *Add EPerson*

> Menambahkan role admin ke e-person tertentu bisa dilakukan lewat halaman **Groups** di UI yang sama (masukkan e-person ke grup `Administrator`).

---

*Catatan: dokumen ini sengaja tidak mencantumkan kredensial DSpace/database apa pun — cek langsung di environment variable pada `docker-compose.yml` atau file `.env` (jika dipakai) di masing-masing environment kamu.*