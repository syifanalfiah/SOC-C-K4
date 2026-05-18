# Setup Wazuh Manager (Microsoft Azure for Students)

Panduan ini dikhususkan untuk deployment Wazuh SIEM menggunakan **Azure for Students**, yang memberikan Virtual Machine gratis dengan spesifikasi yang sangat mumpuni (4GB RAM) tanpa memerlukan kartu kredit.

---

## Step 1: Pendaftaran Azure for Students

Syarat utama: Kamu wajib punya email kampus aktif (berakhiran `.ac.id` atau `.edu`).

1. Buka Halaman Registrasi: [Azure for Students](https://azure.microsoft.com/en-us/free/students/).
2. Klik tombol **Start Free** dan login dengan akun Microsoft kamu.
3. Masukkan nomor telepon untuk verifikasi OTP.
4. Masukkan **Email Kampus** di kolom "Academic email address", lalu verifikasi melalui link yang dikirim ke email tersebut.
5. Isi data diri sesuai KTP/KTM. Kamu akan langsung mendapat credit $100 yang sangat cukup untuk menjalankan Wazuh berbulan-bulan.

---

## Step 2: Membuat Virtual Machine (Server Wazuh)

Setelah berhasil masuk ke [Azure Portal](https://portal.azure.com/):

1. Di kolom pencarian atas, ketik **Virtual Machines**, lalu klik.
2. Klik tombol **Create** -> Pilih **Azure Virtual Machine**.
3. **Bagian Basics:**
   - **Subscription:** Pilih *Azure for Students*.
   - **Resource Group:** Klik *Create new*, beri nama `Wazuh-Project`.
   - **Virtual machine name:** `Wazuh-Manager`.
   - **Region:** `Southeast Asia` (Singapura, agar latency rendah ke Indonesia).
   - **Image:** Pilih **Ubuntu Server 22.04 LTS - x64 Gen2**.
   - **Size:** Cari dan pilih **Standard_B2s** (2 vCPU, 4GB RAM).
4. **Bagian Administrator Account:**
   - **Authentication type:** Pilih **SSH public key** (atau Password jika lebih nyaman).
   - **Username:** `azureuser` (Catat ini!).
   - **Inbound port rules:** Allow selected ports -> Centang **SSH (22)**.
5. **Bagian Disks:**
   - Gunakan *Standard SSD* ukuran **30GB**.
6. Klik **Review + create**, lalu klik **Create**.
7. Download file `.pem` (jika menggunakan SSH Key) dan simpan baik-baik.
8. Tunggu proses deployment selesai.

---

## Step 3: Konfigurasi Firewall (Networking) di Azure

Wazuh butuh beberapa port terbuka agar Dashboard bisa diakses dan Agent dari laptop bisa mengirim data.

1. Buka Virtual Machine `Wazuh-Manager` yang baru dibuat.
2. Di menu kiri, masuk ke bagian **Settings** -> **Networking**.
3. Klik tombol **+ Add inbound port rule**.
4. Isi dengan konfigurasi berikut:
   - **Destination port ranges:** `443, 1514, 1515, 9200`
   - **Protocol:** `TCP`
   - **Action:** `Allow`
   - **Name:** `Wazuh-Ports`
5. Klik **Add**.

---

## Step 4: Login SSH ke Server

Buka terminal di laptopmu (Git Bash, Command Prompt, atau Terminal di Mac/Linux). Catat **Public IP address** dari halaman overview VM di Azure.

```bash
# Jika mendaftar pakai SSH Key (.pem)
ssh -i "nama-key-kamu.pem" azureuser@70.153.19.42

# Jika mendaftar pakai Password
ssh azureuser@70.153.19.42
```

Jika ada prompt `Are you sure you want to continue connecting (yes/no/[fingerprint])?`, ketik **yes** lalu Enter.

---

## Step 5: Install Wazuh Manager (All-in-One)

Kamu tidak perlu pusing mengkonfigurasi manual. Kami sudah menyiapkan script yang akan melakukan semuanya. Jalankan perintah berikut bertahap di terminal Azure:

```bash
# 1. Pindah ke user root
sudo su

# 2. Download installer bawaan Wazuh
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
curl -sO https://packages.wazuh.com/4.9/config.yml

# 3. Masukkan IP Public Azure ke config.yml
# Kamu bisa pakai text editor nano:
nano config.yml

# Ganti TIGA baris "ip: <NODE_IP>" menjadi IP Public Azure kamu. (Ini sudah tidak perlu dilakukan karena pakai script otomatis di chat sebelumnya)
# Simpan dengan cara tekan Ctrl+X, ketik Y, lalu Enter.

# 4. Generate konfigurasi enkripsi
bash wazuh-install.sh --generate-config-files

# 5. Jalankan instalasi utama (Ini butuh waktu sekitar 10-15 menit)
bash wazuh-install.sh --all-in-one
```

> **INFO:** Karena RAM server Azure adalah 4GB, proses ini akan berjalan lancar tanpa perlu membuat Swap memory tambahan. Tunggu saja hingga selesai.

---

## Step 6: Akses Dashboard & Catat Password

Setelah instalasi selesai (langkah 5), terminal akan menampilkan output penting seperti ini:

```text
INFO: --- Summary ---
INFO: You can access the web interface https://70.153.19.42:443
    User: admin
    Password: <PASSWORD_ACAK>
INFO: Installation finished.
```

1. **Wajib:** Blok dan Copy password acak tersebut, lalu simpan di Notepad!
2. Buka browser web (Chrome/Firefox) dan ketikkan `https://70.153.19.42`.
3. Akan muncul peringatan "Your connection is not private". Ini hal normal.
   - Klik **Advanced** (Lanjutan).
   - Klik **Proceed to IP / Accept the Risk and Continue**.
4. Login menggunakan username `admin` dan password yang telah kamu catat.

---

## Troubleshooting Cepat

Jika ada masalah:

1. **Dashboard tidak bisa diakses:** Pastikan kamu sudah mengerjakan **Step 3** (Networking di portal Azure) dan port 443 sudah ditambahkan.
2. **Agent tidak mau connect:** Pastikan port 1514 dan 1515 juga sudah dimasukkan di Inbound port rule Azure.
3. **Lupa Password Dashboard:** Jalankan perintah ini di SSH server:
   ```bash
   sudo tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O | grep -A 1 "indexer"
   ```
