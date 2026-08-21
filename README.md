# Portal Pengaduan Warga Kelurahan Songgokerto

Website satu halaman untuk menerima dan mengelola laporan/pengaduan warga di tingkat kelurahan. Warga mengisi formulir, mendapat nomor tiket, lalu petugas dapat memantau dan mengubah status laporan (Menunggu → Diproses → Selesai) lewat halaman yang sama.

## Isi folder

```
portal-pengaduan-kelurahan/
├── index.html   ← seluruh website (HTML, CSS, JS jadi satu file)
└── README.md    ← panduan ini
```

## Cara membuka

Cukup buka `index.html` langsung di browser (klik dua kali), atau upload folder ini ke layanan hosting statis apa pun:

- **GitHub Pages** — upload folder ke repo, aktifkan Pages, arahkan ke `index.html`.
- **Netlify / Vercel** — seret folder ini ke dashboard "deploy" mereka.
- **Server kelurahan / komputer lokal** — cukup taruh folder ini di web server (Apache/Nginx) atau buka langsung dari file explorer.

Tidak ada proses instalasi, tidak butuh internet, tidak butuh database eksternal.

## Tentang penyimpanan data

Website ini awalnya dibuat sebagai *artifact* di Claude.ai, yang menyediakan penyimpanan otomatis (`window.storage`) sehingga data laporan tersimpan dan bisa dilihat bersama oleh siapa pun yang membuka artifact tersebut.

Setelah dijadikan file mandiri seperti ini, portal menggunakan Supabase untuk autentikasi dan penyimpanan data. Salinan lokal `localStorage` tetap dipakai sebagai cadangan pada browser yang sama jika koneksi Supabase sedang gagal.

- Masyarakat dapat langsung mengirim laporan tanpa login.
- Laporan dapat menyertakan satu foto pendukung maksimal 5 MB. Foto dikompresi otomatis di browser.
- Foto disimpan di Supabase Storage pada bucket `report-photos`, lalu URL-nya ditampilkan di dashboard admin.
- Pelapor dapat menghapus salinan laporan dari riwayat HP. Data di dashboard admin tetap tersimpan.
- Daftar laporan dan rekapitulasi tidak ditampilkan kepada masyarakat umum.
- Dashboard admin hanya tampil untuk akun yang tercatat di tabel `admin_users`.

### Supaya data tersimpan permanen dan bisa diakses dari luar

Untuk pemakaian nyata di kelurahan, sambungkan formulir ke penyimpanan sungguhan, misalnya:

1. **Supabase** (sudah dipersiapkan di kode ini) — paling cepat untuk website statis. Datanya bisa diakses dari mana saja, dan admin bisa menerima atau menolak laporan dari panel admin.
2. **Firebase** — sama-sama cocok untuk aplikasi web realtime, lalu admin membaca dari database yang sama.
3. **Backend sendiri** (MySQL/PostgreSQL di server kelurahan) — cocok jika ingin login petugas dan hak akses berjenjang.
4. **Formulir pihak ketiga** (Google Form) yang hasilnya diringkas manual di halaman rekap.

### Cara aktifkan Supabase

1. Buat project di Supabase.
2. Buka SQL Editor dan jalankan isi file `supabase.sql`.
3. Buka Project Settings → API.
4. Salin `Project URL` dan `anon/public key`.
5. Edit blok berikut di file `index.html`:

```html
<script>
  window.SUPABASE_CONFIG = {
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key'
  };
</script>
```

6. Simpan file, lalu buka situs di browser. Jika konfigurasi benar, data laporan akan tersimpan di cloud dan bisa diakses dari perangkat lain.

### Membuat akun admin

1. Di Supabase buka **Authentication → Users → Add user**, lalu buat akun dengan email `admin@kelurahan-sukamaju.id`.
2. Jalankan ulang seluruh isi `supabase.sql` di SQL Editor. Bagian terakhir akan mencari UID akun berdasarkan email secara otomatis.

```sql
insert into public.admin_users (user_id)
select id from auth.users
where lower(email) = lower('admin@kelurahan-sukamaju.id')
on conflict (user_id) do nothing;
```

Akun yang tidak tercatat di `admin_users` tetap dapat menjadi akun masyarakat, tetapi tidak dapat membuka dashboard admin.

Masyarakat tidak perlu membuat akun. Mereka dapat langsung mengisi formulir pengaduan. Hanya admin yang membutuhkan akun Supabase untuk membuka dashboard.

## Menyesuaikan isi

Beberapa hal yang mudah diganti langsung di `index.html`:

- **Nama kelurahan**: cari teks "Kelurahan Songgokerto" di bagian kop surat, ganti sesuai nama kelurahan Anda.
- **Kategori laporan**: cari `<select id="f-kategori">` dan `<select id="filter-kategori">`, tambah/ubah pilihan `<option>` di keduanya secara bersamaan.
- **Warna & tampilan**: semua warna diatur di bagian `:root { ... }` paling atas file (variabel seperti `--pine`, `--rust`, `--gold`).
